@ECHO OFF
::
:: scan-submitted-only.bat - Check the file integrity of the submitted sheets
::

bin\scan2.rb config submitted

START scan.log
