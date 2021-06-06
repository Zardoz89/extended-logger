/**
Pseudo tests of ConsoleLogger
*/
module logger.consolelogger_spec;

import logger;
import std.experimental.logger;

import pijamas;

@("consolelogger")
unittest
{
    auto logger = new ConsoleLogger(LogLevel.all);
    logger.log("Log");
    logger.trace("Tracing");
    logger.info("Info");
    logger.warning("Warning");
    logger.error("Error");
    logger.critical("Critical");
}
