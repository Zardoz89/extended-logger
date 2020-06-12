module logger.consolelogger;

import std.experimental.logger;
import logger.extendedfilelogger;

/**
 * A simple color mapping that sets:
 *
 * - all : White tint, black background
 * - trace : White tint, black background
 * - info : Green tint, black background
 * - warning : Yellow tint, black background
 * - error : Red tint, black background
 * - critical : Underline bright red tint, black background
 * - fatal : Black tint, bright red background
 */
enum string[LogLevel] defaultColorMap = [
    LogLevel.all:       "\033[37;40m",
    LogLevel.trace:     "\033[37;40m",
    LogLevel.info:      "\033[32;40m",
    LogLevel.warning:   "\033[33;40m",
    LogLevel.error:     "\033[31;40m",
    LogLevel.critical:  "\033[4;91;40m",
    LogLevel.fatal:     "\033[30;101m"
];

/**
 * ConfigurableLogPattern that colorizes log level with ANSI escape codes
 */
class ConfigurableAnsiLogPattern : ConfigurableLogPattern
{
    private const string[LogLevel] colorMap;

    /**
     * Builds a configurable log pattern
     * Params:
     *  colorMap = An dicctionary mapping loglevel to ANSI escape code. By default uses `defaultColorMap`
     *  logPattern = String pattern to apply. By default uses `simplePattern`
     */
    this(const string[LogLevel] colorMap = defaultColorMap, string logPattern = simplePattern)
    {
        super(logPattern);
        this.colorMap = colorMap;
    }

    /// string preceding loglevel. Usefull to colorize it, with ANSI
    override
    protected string logLevelPrefix(const LogLevel logLevel) {
        return this.colorMap.get(logLevel, "");
    }

    /// string following loglevel. Usefull to colorize it, with ANSI
    override
    protected string logLevelPostfix(const LogLevel logLevel) {
        return "\033[0m";
    }  
}

/// Extends PatternFileLogger to log only to stdout and to use by default ConfigurableAnsiLogPattern
class ConsoleLogger : ExtendedFileLogger
{
    /**
     * A constructor for the `FileLogger` Logger.
     * Params:
     *  lv = The `LogLevel` for the `FileLogger`. By default is LogLevel.all
     *  logPattern = An implementation of the `ILogPattern`. By default uses ConfigurableAnsiLogPattern.
    Example:
    -------------
    auto l1 = new ConsoleLogger();
    auto l2 = new ConsoleLogger(LogLevel.fatal);
    auto l3 = new ConsoleLogger(LogLevel.fatal, new SimpleLogPattern());
    -------------
    */
    this(const LogLevel lv = LogLevel.all, ILogPattern logPattern = new ConfigurableAnsiLogPattern())
    @trusted
    {
        import std.stdio : stdout;
        super(stdout, lv, logPattern);
    }

}
