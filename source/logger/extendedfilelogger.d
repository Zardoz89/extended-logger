module logger.extendedfilelogger;

import std.experimental.logger;
import std.stdio;

import std.concurrency : Tid;
import std.datetime.systime : SysTime;
import std.range : isOutputRange, isInputRange;

private enum PatternToken = '%';

/// A simple pattern -  020-06-08T17:50:25.673 info     :
enum string simplePattern = "%d %-8p: ";

/// Interface of all log patterns
interface ILogPattern
{
    /**
     * Writes on a outputRange of chars, the logging pattern
     * Params:
     *  outputFile = output File where where tow rite the logging request.
     *  file = file name where the logging request was issued.
     *  line = line number from where the logging request was issued.
     *  funcName = the function or method name where the logging request was issued.
     *  prettyFuncName = the function or method prettyfied name where the logging request was issued.
     *  moduleName = the module name where the logging request was issued.
     *  logLevel = the actual log level of the accepter logging request.
     *  threadId = the thread id where the logging request was issued.
     *  timestamp = the timestamp of the logging request.
     *  timestamp = the timestamp of when the logger was created.
     */
    void applyPattern (File outputFile, string file, int line, string funcName,
        string prettyFuncName, string moduleName, LogLevel logLevel, Tid threadId, SysTime timestamp,
        SysTime startTimeStamp ) @trusted;

}

/// Simple loging pattern that outputs the same pattern that classic FileLogger
class SimpleLogPattern : ILogPattern
{
    /**
     * Writes on a outputRange of chars, the logging pattern
     * Params:
     *  outputFile = output File where where tow rite the logging request.
     *  file = file name where the logging request was issued.
     *  line = line number from where the logging request was issued.
     *  funcName = the function or method name where the logging request was issued.
     *  prettyFuncName = the function or method prettyfied name where the logging request was issued.
     *  moduleName = the module name where the logging request was issued.
     *  logLevel = the actual log level of the accepter logging request.
     *  threadId = the thread id where the logging request was issued.
     *  timestamp = the timestamp of the logging request.
     *  timestamp = the timestamp of when the logger was created.
     */
    void applyPattern (File outputFile, string file, int line, string funcName,
        string prettyFuncName, string moduleName, LogLevel logLevel, Tid threadId, SysTime timestamp,
        SysTime startTimeStamp ) @trusted
    {
        auto lt = outputFile.lockingTextWriter();
        import std.experimental.logger.core : systimeToISOString;
        systimeToISOString(lt, timestamp);

        import std.conv : to;
        import std.format : formattedWrite;
        formattedWrite(lt, " [%s] %s:%u:%s ", logLevel.to!string, file, line, funcName);
    }
}

/**
 * Configurable logging pattern that parses a string pattern
 *
 * The pattern it's based of log4j pattern layout format:
 * | Conversion Character | Effect |
 * | -------------------- | -----: |
 * | m | Module name |
 * | d | Used to output the date of the logging event. Actually only outputs on ISO format |
 * | F | Used to output the file name where the logging request was issued. |
 * | L | Used to output the line number from where the logging request was issued. |
 * | M | Used to output the function or method name where the logging request was issued. |
 * | p | Used to output the priority of the logging event. |
 * | r | Used to output number of milliseconds elapsed from the construction of this logger until the logging event. |
 * | t | Used to output the thread that generated the logging event. |
 */
class ConfigurableLogPattern : ILogPattern
{
    private string logPattern;

    /**
     * Builds a configurable log pattern
     * Params:
     *  logPattern = String pattern to apply. By default uses `simplePattern`
     */
    this(string logPattern = simplePattern) @safe
    {
        this.logPattern = logPattern;
    }

    /**
     * Writes on a outputRange of chars, the logging pattern
     * Params:
     *  outputFile = output File where where tow rite the logging request.
     *  file = file name where the logging request was issued.
     *  line = line number from where the logging request was issued.
     *  funcName = the function or method name where the logging request was issued.
     *  prettyFuncName = the function or method prettyfied name where the logging request was issued.
     *  moduleName = the module name where the logging request was issued.
     *  logLevel = the actual log level of the accepter logging request.
     *  threadId = the thread id where the logging request was issued.
     *  timestamp = the timestamp of the logging request.
     *  timestamp = the timestamp of when the logger was created.
     */
    void applyPattern (File outputFile, string file, int line, string funcName,
        string prettyFuncName, string moduleName, LogLevel logLevel, Tid threadId, SysTime timestamp,
        SysTime startTimeStamp ) @trusted
    {
        auto lt = outputFile.lockingTextWriter();

        import std.uni : byCodePoint;
        this.parsePattern(lt, this.logPattern.byCodePoint, file, line, funcName, prettyFuncName, moduleName,
            logLevel, threadId, timestamp, startTimeStamp);
    }

    private void parsePattern(OutputRange, InputRange)(OutputRange outputRange, InputRange patternRange, string file,
        int line, string funcName, string prettyFuncName, string moduleName, LogLevel logLevel, Tid threadId,
        SysTime timestamp, SysTime startTimeStamp ) @trusted
    if (isOutputRange!(OutputRange, char) && isInputRange!(InputRange))
    {
        // Outputs anything before finding the '%' format special character
        while(!patternRange.empty && patternRange.front != PatternToken) {
            outputRange.put(patternRange.front);
            patternRange.popFront;
        }
        if (patternRange.empty) {
            return;
        }
        patternRange.popFront; // And consumes the '%'

        auto modifier = this.formatModifier!(InputRange)(patternRange);

        // Value stores the output string
        import std.conv : to;
        switch (patternRange.front) {
            case '%': // The sequence %% outputs a single percent sign.
                outputRange.put('%');
                break;

            case 'm': // Module name
                outputRange.writeWithModifier(moduleName, modifier[0], modifier[1]);
                break;

            case 'd': // Date on ISO format
            outputRange.systimeToISOString(timestamp);
            break;

            case 'p': // priority of log level
            outputRange.put(this.logLevelPrefix(logLevel));
            outputRange.writeWithModifier(logLevel.to!string, modifier[0], modifier[1]);
            outputRange.put(this.logLevelPostfix(logLevel));
            break;

            case 'F': // Filename
            outputRange.writeWithModifier(file, modifier[0], modifier[1]);
            break;

            case 'L': // Lines
            outputRange.writeWithModifier(line.to!string, modifier[0], modifier[1]);
            break;

            case 'M': // Function/Method where the logging was issued
            outputRange.writeWithModifier(funcName, modifier[0], modifier[1]);
            break;

            case 't': // name of the thread that generated the logging event.
            outputRange.writeWithModifier(threadId.to!string, modifier[0], modifier[1]);
            break;

            case 'r': // number of milliseconds elapsed from the construction of this logger until the logging event.
            import std.datetime : Clock;
            const delta = (Clock.currTime() - startTimeStamp).total!"msecs";
            outputRange.writeWithModifier(delta.to!string, modifier[0], modifier[1]);
            break;

            default: // unsuported formats are simply ignored

        }
        patternRange.popFront;

        // Iterate for the next pattern token
        if (!patternRange.empty) {
            this.parsePattern(outputRange, patternRange, file, line, funcName, prettyFuncName, moduleName,
                logLevel, threadId, timestamp, startTimeStamp);
        }
    }

    private auto formatModifier(InputRange)(ref InputRange patternRange) @safe pure
        if (isInputRange!(InputRange))
    {
        import std.ascii : isDigit;
        import std.typecons : Tuple, tuple;
        Tuple!(int, size_t) modifier = tuple(0, size_t.max);

        // Get the padding modifier
        if (patternRange.front == '+' || patternRange.front == '-' || patternRange.front.isDigit) {
            import std.conv : parse, ConvException;
            try {
                modifier[0] = patternRange.parse!int;
            } catch (ConvException ex) {
                // We ignore it silently
            }
        }
        // Get the truncate modifier
        if (patternRange.front == '.') {
            patternRange.popFront; // Consume the '.' separator
            if (patternRange.front.isDigit) {
                import std.conv : parse, ConvException;
                try {
                    modifier[1] = patternRange.parse!size_t;
                } catch (ConvException ex) {
                    // Silently we ignore it
                }
            }
        }
        return modifier;
    }

    /// string preceding loglevel. Usefull to colorize it, with ANSI
    protected string logLevelPrefix(const LogLevel logLevel) {
        return "";
    }

    /// string following loglevel. Usefull to colorize it, with ANSI
    protected string logLevelPostfix(const LogLevel logLevel) {
        return "";
    }
}

import std.range : isOutputRange;

// writes to the output the value with the padding and truncation
private void writeWithModifier(OutputRange)(OutputRange outputRange, string value, int padding, size_t truncate) @safe
    if (isOutputRange!(OutputRange, char))
{
    if (padding > 0) {
        // left padd
        padding -= value.length;
        while(padding > 0) {
            outputRange.put(' ');
            padding--;
        }
    }
    import std.format : formattedWrite;
    if (truncate != size_t.max && truncate < value.length) {
        outputRange.formattedWrite("%s", value[0..truncate]);
    } else {
        outputRange.formattedWrite("%s", value);
    }
    if (padding < 0) {
        // right padd
        padding += value.length;
        while(padding < 0) {
            outputRange.put(' ');
            padding++;
        }
    }
}

/**
 * Extends FileLogger to support configurable pattern
 */
class ExtendedFileLogger : FileLogger
{
    import std.concurrency : Tid;
    import std.datetime.systime : SysTime;
    import std.format : formattedWrite;

    /** A constructor for the `ExtendedFileLogger` Logger.
    Params:
      fn = The filename of the output file of the `ExtendedFileLogger`. If that
      file can not be opened for writting an exception will be thrown.
      lv = The `LogLevel` for the `ExtendedFileLogger`. By default the
      logPattern = An implementation of the `ILogPattern`. By default uses SimpleLogPattern.
    Example:
    -------------
    auto l1 = new ExtendedFileLogger("logFile");
    auto l2 = new ExtendedFileLogger("logFile", LogLevel.fatal);
    auto l3 = new ExtendedFileLogger("logFile", LogLevel.fatal, new ConfigurableLogPattern("%m %-5p %d - "));
    -------------
    */
    this(const string fn, const LogLevel lv = LogLevel.all, ILogPattern logPattern = new SimpleLogPattern()) @safe
    {
         this(fn, lv, logPattern, CreateFolder.yes);
    }

    /** A constructor for the `ExtendedFileLogger` Logger that takes a reference to a `File`.
    The `File` passed must be open for all the log call to the `ExtendedFileLogger`. If the `File`
    gets closed, using the `ExtendedFileLogger` for logging will result in undefined behaviour.
    Params:
      fn = The file used for logging.
      lv = The `LogLevel` for the `ExtendedFileLogger`. By default the `LogLevel` for
      `ExtendedFileLogger` is `LogLevel.all`.
      createFileNameFolder = if yes and fn contains a folder name, this folder will be created.
      logPattern = An implementation of the `ILogPattern`.
    Example:
    -------------
    auto file = File("logFile.log", "w");
    auto l1 = new ExtendedFileLogger(file);
    auto l2 = new ExtendedFileLogger(file, LogLevel.fatal);
    -------------
    */
    this(const string fn, const LogLevel lv, ILogPattern logPattern, CreateFolder createFileNameFolder) @safe
    {
        import std.datetime : Clock;
        super(fn, lv, createFileNameFolder);
        this.logPattern = logPattern;
        this.startTimeStamp =  Clock.currTime();
    }

    /** A constructor for the `ExtendedFileLogger` Logger that takes a reference to a `File`.
    The `File` passed must be open for all the log call to the `ExtendedFileLogger`. If
    the `File` gets closed, using the `ExtendedFileLogger` for logging will result in
    undefined behaviour.
    Params:
      file = The file used for logging.
      lv = The `LogLevel` for the `ExtendedFileLogger`. By default the `LogLevel` for
      `ExtendedFileLogger` is `LogLevel.all`.
      logPattern = An implementation of the `ILogPattern`. By default uses SimpleLogPattern.
    Example:
    -------------
    auto file = File("logFile.log", "w");
    auto l1 = new ExtendedFileLogger(file);
    auto l2 = new ExtendedFileLogger(file, LogLevel.fatal);
    -------------
    */
    this(File file, const LogLevel lv = LogLevel.all, ILogPattern logPattern = new SimpleLogPattern()) @safe
    {
        import std.datetime : Clock;
        super(file, lv);
        this.logPattern = logPattern;
        this.startTimeStamp =  Clock.currTime();
    }

    /// This method overrides the base class method in order to call the log pattern
    override protected void beginLogMsg(string file, int line, string funcName,
        string prettyFuncName, string moduleName, LogLevel logLevel,
        Tid threadId, SysTime timestamp, Logger logger)
        @safe
    {
        import std.string : lastIndexOf;
        ptrdiff_t fnIdx = file.lastIndexOf('/') + 1;
        ptrdiff_t funIdx = funcName.lastIndexOf('.') + 1;

        this.logPattern.applyPattern(this.file, file[fnIdx..$], line, funcName[funIdx..$], prettyFuncName, moduleName,
            logLevel, threadId, timestamp, this.startTimeStamp);
    }

    protected ILogPattern logPattern;
    protected SysTime startTimeStamp;
}

