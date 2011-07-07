@ECHO OFF
:
: scan-approved-only.bat - Check the file integrity of the approved sheets
:

IF EXIST scan.log DEL scan.log

bin\scan2.rb config approved

START scan.log
