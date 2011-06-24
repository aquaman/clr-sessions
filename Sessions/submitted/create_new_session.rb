#! /usr/bin/env ruby
# -----
# create_new_session.rb
#
# Purpose: Create a new empty ET session sheet. Use the required sections in SBTM.YML and the latest found sheet to create the next one.
#
# Command Line Options : None. The script will move up through the folder tree looking for the following sub-directories:
# 1. 'config' folder containing the SBTM.YML configuration file (to read the tester information - name & initials)
# 2. 'approved' folder
# 3. 'submitted' folder (default location for writing the new session sheet to)
#
# -----
# Author:: Paul Carvalho
# Last Updated:: 15 June 2011
# -----

### NOTES ###

## SPECIFY THE DATE/TIME FORMAT YOU WANT TO SEE IN
## YOUR SESSION SHEETS IN THE SBTM.YML CONFIG FILE

## CHANGE THESE FOLDER NAMES IF YOUR LOCATIONS ARE DIFFERENT
approved_folder = 'approved'
submitted_folder = 'submitted'


### START ###

# Find the 'config' folder location; keep moving up the folder tree from the current script location:
Dir.chdir( File.expand_path( File.dirname(__FILE__) ) )
Dir.chdir('..') while ( not Dir.entries('.').include? 'config' ) and ( Dir.pwd !~ /\/$/ )

##
# Exit gracefully and show a message indicating what failed. The 'message' parameter is an array.
#
def setup_fail( message )
  puts '-'*50
  message.each {|line| puts line}
  puts '-'*50
  exit
end

# Check the folders:
message = []
unless Dir.entries('.').include? 'config'
  message << "Warning! Could not find the 'config' directory!"
  message << "Please place this '#{File.basename($0)}' in a sub-directory of 'Sessions'"
  setup_fail( message )
end

unless File.exist?( 'config/sbtm.yml' )
  message << "Problem Found! Unable to find the SBTM.YML configuration file!"
  message << "Please ensure the 'config' directory contains the SBTM.YML file"
  setup_fail( message )
end

[ approved_folder, submitted_folder ].each do |folder|
  folder.gsub!('\\','/')  # (make sure the /'s are forward)
  unless FileTest.directory?( folder )
    message << "'#{ folder }' is not a valid directory!" 
    message << "Please check the name specified and try again."
    setup_fail( message )
  end
  folder << '/' if folder[-1,1] != '/'
end


### SETUP ###

# Read the Configuration file:
require 'yaml'
config = YAML.load_file( 'config/sbtm.yml' )

begin
  tester_info = config['tester_ID']
  @include_switch = config['scan_options']
  output = config['output']
  
 raise if tester_info.nil? or @include_switch.nil? or output.nil?
rescue
  message << 'Error reading values from SBTM.YML!'
  message << 'Please check to make sure all required values exist.'
  setup_fail( message )
end

# Check to make sure the tester info is not empty:
if ( tester_info['full name'].nil? ) or ( tester_info['initials'].nil? ) or 
  ( tester_info['initials'].length < 2 ) or ( tester_info['initials'].length > 3 ) 
  
  message << 'SBTM.YML needs to be updated!'
  message << 'Please update the Tester ID section with your full name and initials'
  message << "'full name' = '#{ tester_info['full name'] }'"
  
  init_string = "'initials'  = '#{ tester_info['initials'] }'" 
  init_length = 0
  init_length = tester_info['initials'].length unless tester_info['initials'].nil?
  init_string += " <-- Must be 2 or 3 letters" if ( init_length < 2 ) or ( init_length > 3 )
  message << init_string
  
  setup_fail( message )
end

# Check to make sure the Date & Time formats are present:
if ( output['date format'].nil? ) or ( output['time format'].nil? )
  # (it would be nice to add a regex here to check for basic expected formatting)
  
  message << 'SBTM.YML needs to be updated!'
  message << 'Please update the Output section with the Date and Time formats'
  message << "'date format' = '#{ output['date format'] }'"
  message << "'time format' = '#{ output['time format'] }'" 
  
  setup_fail( message )
end


# Create main body of the template
mainbody = ''
dashedline = '-' * 50 + "\n"

mainbody << "CHARTER\n"
mainbody << dashedline + "\n"
mainbody << "\n#LTTD_AREA\n\n" if @include_switch['LTTD']
mainbody << "\n#AREAS\n\n" if @include_switch['Areas']
mainbody << "\nSTART\n"
mainbody << dashedline

# Add time stamp here!
datetime_format = output['date format'] + ' ' + output['time format']
mainbody << Time.now.strftime(datetime_format + "\n\n")

mainbody << "TESTER\n"
mainbody << dashedline

# Add Tester Name here!
mainbody << tester_info['full name'] + "\n\n"

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
mainbody << dashedline + "\n"*4
mainbody << "BUGS\n"
mainbody << dashedline
mainbody << "#N/A\n\n"
mainbody << "ISSUES\n"
mainbody << dashedline
mainbody << "#N/A\n"


### MAIN ###

# Look for previous sessions by this tester to figure out what the next session sheet label should be

next_letter = 'a'
previous_files = []
filename_template = "et-#{ tester_info['initials'].downcase }-*.ses"

previous_files << Dir[ approved_folder + filename_template ] + Dir[ submitted_folder + filename_template ] 
previous_files.flatten!

unless previous_files.empty?
  # ( Regex recap: $1 = yymmdd, $2 = single letter )
  previous_files.sort.last.downcase =~ /-(\d{6})-(\w)\./
  next_letter = $2.next if ( Time.now.strftime("%y%m%d") == $1 )
end

# Create the file - in the Submitted folder:

new_et_session_name = "et-#{ tester_info['initials'].downcase }-#{ Time.now.strftime("%y%m%d") }-#{ next_letter }.ses"

et_file = File.new( submitted_folder + new_et_session_name,  'w' )
et_file.puts mainbody
et_file.close

puts "\n** Created new file: " + submitted_folder + new_et_session_name

### END ###