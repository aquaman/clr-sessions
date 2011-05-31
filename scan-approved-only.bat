@ECHO OFF
::
:: scan-approved-only.bat - Check the file integrity of the approved sheets
::

bin\scan2.rb config approved

START scan.log
