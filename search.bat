@ECHO OFF
::
:: search.bat - search Approved folder session sheets
::

: # Delete output file, if present
DEL sheets.txt

: # Search the specified folder and save the output in the current folder
bin\search.rb approved .

START sheets.txt
