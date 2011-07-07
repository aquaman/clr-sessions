@ECHO OFF
:
: todo-maker.bat - Create empty session sheets based on 'to do' list
:
: Run this batch file from C:\Sessions
: Input file is todo.xls in the C:\Sessions\Todo folder, *not* the TXT file.

bin\todomaker_win_xls.rb config todo\todo.xls
