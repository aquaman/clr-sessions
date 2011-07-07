@ECHO OFF
:
: search.bat - search Approved folder session sheets
:

: # Delete output file, if present
IF EXIST search_results_sheets.txt DEL search_results_sheets.txt

: # Search the specified folder and save the output in the current folder
bin\search.rb approved

IF EXIST search_results_sheets.txt START search_results_sheets.txt
