/**
Specification of ExtendedFileLogger
*/
module logger.extendedfilelogger_spec;

import logger;

import pijamas;

import std.array : array;
import std.stdio : File;
import std.file : tempDir;
import std.algorithm : map, findSkip;
import std.path : buildPath;
import std.experimental.logger;

private enum string outputfile = "output.log";

private auto outputFilePath()
{
    return buildPath(tempDir, outputfile);
}

@("extendedfilelogger")
unittest
{
    // describe("logging with simple log pattern must result on the expected log pattern")
    {
        // given("We create a ExtendedFileLogger with a SimpleLogPattern")
        auto file = File(outputFilePath(), "w"); // Overwrite file
        auto logger = new ExtendedFileLogger(file, LogLevel.all, new SimpleLogPattern());

        // when("we output some entries to the logger")
        logger.log("Log");
        logger.trace("Trace");
        logger.info("Info");
        logger.warning("Warning");
        logger.error("Error");
        logger.critical("Critical");
        //logger.fatal("fatal");

        // then("the output file must containt the same number of lines that log events")
        file.close();
        auto output = File(outputFilePath(), "r").byLineCopy.array;
        output.should.have.length(6);

        // and("each line must have the expected format")
        // On windows, the SimpleLogPattern, appends two levels of directory name. A bug ?
        output[0].should.match(`[0-9T\-:.]+ \[all\] (tests[\\/]logger[\\/])?extendedfilelogger_spec.d:[0-9]+:[a-zA-Z0-9_]+ Log`);
        output[1].should.match(`[0-9T\-:.]+ \[trace\] (tests[\\/]logger[\\/])?extendedfilelogger_spec.d:[0-9]+:[a-zA-Z0-9_]+ Trace`);
        output[2].should.match(`[0-9T\-:.]+ \[info\] (tests[\\/]logger[\\/])?extendedfilelogger_spec.d:[0-9]+:[a-zA-Z0-9_]+ Info`);
        output[3].should.match(`[0-9T\-:.]+ \[warning\] (tests[\\/]logger[\\/])?extendedfilelogger_spec.d:[0-9]+:[a-zA-Z0-9_]+ Warning`);
        output[4].should.match(`[0-9T\-:.]+ \[error\] (tests[\\/]logger[\\/])?extendedfilelogger_spec.d:[0-9]+:[a-zA-Z0-9_]+ Error`);
        output[5].should.match(`[0-9T\-:.]+ \[critical\] (tests[\\/]logger[\\/])?extendedfilelogger_spec.d:[0-9]+:[a-zA-Z0-9_]+ Critical`);
    }

    // describe("logging with ConfigurableLogPattern and simplePattern must result on the expected log pattern")
    {
        // given("We create a ExtendedFileLogger with a ConfigurableLogPattern")
        auto file = File(outputFilePath(), "w"); // Overwrite file
        auto logger = new ExtendedFileLogger(file, LogLevel.all, new ConfigurableLogPattern(simplePattern));

        // when("we output some entries to the logger")
        logger.log("Log");
        logger.trace("Trace");
        logger.info("Info");
        logger.warning("Warning");
        logger.error("Error");
        logger.critical("Critical");
        //logger.fatal("fatal");

        // then("the output file must containt the same number of lines that log events")
        file.close();
        auto output = File(outputFilePath(), "r").byLineCopy.array;
        output.should.have.length(6);

        // and("each line must have the expected format")
        output[0].should.match(`[0-9T\-:.]+ all     : Log`);
        output[1].should.match(`[0-9T\-:.]+ trace   : Trace`);
        output[2].should.match(`[0-9T\-:.]+ info    : Info`);
        output[3].should.match(`[0-9T\-:.]+ warning : Warning`);
        output[4].should.match(`[0-9T\-:.]+ error   : Error`);
        output[5].should.match(`[0-9T\-:.]+ critical: Critical`);
    }

    // describe("logging with ConfigurableLogPattern and custum pattern with all options must result on the expected log pattern")
    {
        // given("We create a ExtendedFileLogger with a ConfigurableLogPattern")
        const string pattern = "%d %2.2p %m %r [%t] ";
        auto file = File(outputFilePath(), "w"); // Overwrite file
        auto logger = new ExtendedFileLogger(file, LogLevel.all, new ConfigurableLogPattern(pattern));

        // when("we output some entries to the logger")
        logger.log("Log");
        logger.trace("Trace");
        logger.info("Info");
        logger.warning("Warning");
        logger.error("Error");
        logger.critical("Critical");
        //logger.fatal("fatal");

        // then("the output file must containt the same number of lines that log events")
        file.close();
        auto output = File(outputFilePath(), "r").byLineCopy.array;
        output.should.have.length(6);

        // and("each line must have the expected format")
        output[0].should.match(`[0-9T\-:.]+ al logger.extendedfilelogger_spec [0-9]+ \[Tid\([0-9a-f]+\)\] Log`);
        output[1].should.match(`[0-9T\-:.]+ tr logger.extendedfilelogger_spec [0-9]+ \[Tid\([0-9a-f]+\)\] Trace`);
        output[2].should.match(`[0-9T\-:.]+ in logger.extendedfilelogger_spec [0-9]+ \[Tid\([0-9a-f]+\)\] Info`);
        output[3].should.match(`[0-9T\-:.]+ wa logger.extendedfilelogger_spec [0-9]+ \[Tid\([0-9a-f]+\)\] Warning`);
        output[4].should.match(`[0-9T\-:.]+ er logger.extendedfilelogger_spec [0-9]+ \[Tid\([0-9a-f]+\)\] Error`);
        output[5].should.match(`[0-9T\-:.]+ cr logger.extendedfilelogger_spec [0-9]+ \[Tid\([0-9a-f]+\)\] Critical`);
    }
}

