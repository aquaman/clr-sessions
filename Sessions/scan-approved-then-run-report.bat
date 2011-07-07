@ECHO OFF
:
: scan-approved-then-run-report.bat
:

: Remove previous report files before generating new ones (Optional, but nice to do)
: (NOTE: This _assumes_ the files are in the 'reports' subfolder)

DEL reports\breakdowns*.txt
DEL reports\charters*.txt
DEL reports\data.txt
DEL reports\bugs.txt
DEL reports\issues.txt
DEL reports\test*.txt
DEL reports\*.htm
IF EXIST scan.log DEL scan.log


: Check the file integrity of the approved sheets. Create summary files.

bin\scan2.rb config approved
START scan.log


: Generate HTML reports

bin\report2.rb config
START reports\status.htm
