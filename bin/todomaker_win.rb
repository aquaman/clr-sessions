#! /usr/bin/env ruby
# -----
# todomaker_win.rb
#
# Purpose: Create TODO session sheets based on the content in "todo.xls"
#
# NOTE: This script calls MS Excel directly in MS Windows. ONLY run this script if you have both MS Windows and MS Excel installed.
#
# Command Line Options : 2 Required:
# 1. folder location of the SBTM.YML configuration file (specifies the 'todo' destination folder)
# 2. input file - the "todo.xls" file
#
# -----
# Author:: Paul Carvalho
# Last Updated:: 02 June 2011
# Version:: 2.0
# -----

if ( ARGV[0].nil? ) or ( ! File.exist?( ARGV[0] + '/sbtm.yml' ) ) or ( ! File.exist?( ARGV[1] ) )
  puts "\nUsage: #{File.basename($0)} config_dir input_file"
  puts "\nWhere 'config_dir' is the path to the directory containing SBTM.YML"
  puts "and   'input_file' is the 'todo.xls' input file"
  exit
end

### START ###

# Read the Configuration file:
require 'yaml'
config = YAML.load_file( ARGV[0] + '/sbtm.yml' )

begin
  todo_dir = config['folders']['todo_dir']
  @include_switch = config['scan_options']
rescue
  puts '*'*50
  puts 'Error reading value from SBTM.YML!'
  puts '*'*50
  exit
end

# Check to make sure the Windows OLE gem is present. 
begin
  require 'win32ole'
rescue LoadError
  puts '*'*70
  puts 'Missing "win32ole" gem. Please install it and re-run this script!'
  puts 'Otherwise, run the "todomaker.rb" script that uses the TODO.TXT file.'
  puts '*'*70
  exit
end

# Create main body of the template
dashedline = '-' * 50 + "\n"
linebreaks = "\n\n"
mainbody = ''

mainbody << "\nSTART\n"
mainbody << dashedline + linebreaks
mainbody << "TESTER\n"
mainbody << dashedline + linebreaks
if @include_switch['Duration'] or @include_switch['TBS'] or @include_switch['C vs O']
  mainbody << "TASK BREAKDOWN\n"
  mainbody << dashedline
end
mainbody << "#DURATION\n\n\n" if @include_switch['Duration']
if @include_switch['TBS']
  mainbody << "#SESSION SETUP\n\n\n"
  mainbody << "#TEST DESIGN AND EXECUTION\n\n\n"
  mainbody << "#BUG INVESTIGATION AND REPORTING\n\n\n"
end
if @include_switch['C vs O']
  mainbody << "#CHARTER VS. OPPORTUNITY\n"
  mainbody << "100/0\n\n"
end
if @include_switch['Data Files']
  mainbody << "DATA FILES\n"
  mainbody << dashedline
  mainbody << "#N/A\n\n"
end
mainbody << "TEST NOTES\n"
mainbody << dashedline + linebreaks*2
mainbody << "BUGS\n"
mainbody << dashedline
mainbody << "#N/A\n\n"
mainbody << "ISSUES\n"
mainbody << dashedline
mainbody << "#N/A\n\n"


##
# Read in the Excel file and Create new 'Todo' Session sheets
input_file = File.expand_path( ARGV[1] )

excel = WIN32OLE::new('excel.Application')
excel['Visible'] = false
workbook = excel.Workbooks.Open( input_file )     # (must specify the FULL path name here)
worksheet = workbook.Worksheets(1)

line = '2'     # (Skip the Header Row)
while worksheet.Range("a#{line}")['Value']
  data = []
  # (Only interested in the first four columns: [0] Session title, [1] Areas, [2] Priority, [3] Charter)
  data << worksheet.Range("a#{line}:d#{line}")['Value'].flatten     # (2D array)
  data.flatten!     # (make it a 1D array)
  
  todofile =  File.new( todo_dir + '\et-todo-' + data[2].to_i.to_s + '-' + data[0].to_s + '.ses',  'w' )
  
  todofile.puts 'CHARTER'
  todofile.puts dashedline
  todofile.puts data[3]
  
  todofile.puts "\n#LTTD_AREA\n\n" if @include_switch['LTTD']
  
  if @include_switch['Areas']
    todofile.puts "\n#AREAS"
    todofile.puts data[1].gsub(';', "\n")
  end
  
  todofile.puts mainbody
  
  todofile.close
  line.succ!
end

excel.quit()

### END ###