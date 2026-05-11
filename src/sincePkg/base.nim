import logging, os

var l: ConsoleLogger
case getEnv "LOG_LEVEL"
of "INFO":
  l = newConsoleLogger(levelThreshold = lvlInfo)
else:
  l = newConsoleLogger()
l.addHandler
