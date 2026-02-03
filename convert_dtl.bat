@echo off
REM Dialogic DTL to TXT Converter - Windows Batch File
REM Double-click this file to run the converter

echo Starting DTL to TXT Converter...
python dtl_to_txt_converter.py %*

REM Keep window open if there's an error
if errorlevel 1 (
    echo.
    echo Error: Python may not be installed or not in PATH
    echo Please install Python from https://www.python.org/
    pause
)
