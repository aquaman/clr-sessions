#! /usr/bin/env ruby
# -----
# todomaker.rb
#
# Purpose: Create TODO session sheets based on the content of the "todos.txt" file
#
# Command Line Options : 2 Required:
# 1. folder location of the SBT_CONFIG.YML configuration file (specifies the 'todo' destination folder)
# 2. input file - a [TAB]-delimited text file
#
# -----
# Author:: Paul Carvalho
# Last Updated:: 06 July 2011
# Version:: 2.1
# -----

if ( ARGV[0].nil? ) or ( ! File.exist?( ARGV[0] + '/sbt_config.yml' ) ) or ( ! File.exist?( ARGV[1] ) )
  puts "\nUsage: #{File.basename($0)} config_dir input_file"
  puts "\nWhere 'config_dir' is the path to the directory containing SBT_CONFIG.YML"
  puts "and 'input_file' is the 'todos.txt' input file"
  exit
end

if File.extname( ARGV[1] ) == '.xls'
  puts "\nI'm sorry, you specified an .XLS file. I'm expecting a .TXT file."
  exit
end

### START ###

# Read the Configuration file:
require 'yaml'
config = YAML.load_file( ARGV[0] + '/sbt_config.yml' )

begin
  todo_dir = config['folders']['todo_dir']
  @include_switch = config['scan_options']
rescue
  puts '*'*50
  puts 'Error reading value from SBT_CONFIG.YML!'
  puts '*'*50
  exit
end

# Create main body of the template
dashedline = '-' * 50 + "\n"
linebreaks = "\n\n"
mainbody = ''

mainbody << "\n#BUILD\n\n" if @include_switch['Build']
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


# Read the TODO.TXT input file
input_file = File.open( ARGV[1] )
input_file.gets # (skip first/header line)

while (line = input_file.gets)
  (title, area, priority, description) = line.split(/\t/)
  
  todofile = File.new( todo_dir + '/et-todo-' + priority + '-' + title + '.ses', 'w' )
  
  todofile.puts 'CHARTER'
  todofile.puts dashedline
  todofile.puts description.chomp
  
  todofile.puts "\n#LTTD_AREA\n\n" if @include_switch['LTTD']
  
  if @include_switch['Areas']
    todofile.puts "\n#AREAS"
    todofile.puts area.gsub(';', "\n")
  end
  
  todofile.puts mainbody
  
  todofile.close
end

input_file.close

### END ###