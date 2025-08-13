#Requires AutoHotKey v1.1.34.04+
#Include %A_ScriptDir%\lib\debugHelper.ahk

; Test script for debug system
global DebugMode := true

; Initialize debug system
debugInit()

; Test various log functions
debugLog("TEST", "This is a test log entry", "Testing basic logging")
debugLogFunctionCall("testFunction", "testParam", "Testing function call logging")
debugLogKeyPress("A", "Ctrl+Shift", "Testing key press logging")
debugLogModifierPress("Ctrl", "Testing modifier press logging")
debugLogSleep(100, "Test delay", "Testing sleep logging")

; Force flush to see if files are created
debugFlushBuffer()

; Show the log file path
logPath := debugGetLogFilePath()
MsgBox, % "Debug log file created at:`n" . logPath

; Check if file exists
if (FileExist(logPath)) {
    MsgBox, % "SUCCESS: Log file exists at:`n" . logPath
} else {
    MsgBox, % "FAILED: Log file not found at:`n" . logPath
}

ExitApp

