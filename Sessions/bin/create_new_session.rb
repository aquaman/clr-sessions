#! /usr/bin/env ruby
# -----
# create_new_session.rb
#
# Purpose: Create a new empty ET session sheet. Use the required sections in SBTM.YML and the latest found sheet to create the next one.
#
# Command Line Options : 3 Required, all hard-coded for now:
# 1. folder location of the SBTM.YML configuration file (read the tester ID information - name & initials)
# 2. 'approved' folder location
# 3. 'submitted' folder location (default for writing the new session sheet to)
#
# -----
# Author:: Paul Carvalho
# Last Updated:: 03 June 2011
# Version:: 1.0
# -----

## CHANGE THESE TO SUIT YOUR NEEDS ##

base_dir = 'c:/sessions/'

config_dir = base_dir + 'config'
approved_folder = base_dir + 'approved'
submitted_folder = base_dir + 'submitted'

# --------------------------------------------------- #

# Check the folders:
[ config_dir, approved_folder, submitted_folder ].each do |folder|
  folder.gsub!('\\','/')  # (make sure the /'s are forward)
  unless FileTest.directory?( folder )
    puts '*'*50
    puts "'" + folder + "' is not a valid directory!" 
    puts "Please check the name specified and try again."
    puts '*'*50
    exit
  end
end


# Read the Configuration file:
require 'yaml'
config = YAML.load_file( config_dir + '/sbtm.yml' )

begin
  tester_info = config['tester_ID']
  @include_switch = config['scan_options']
  
  raise if tester_info.nil? or @include_switch.nil?
rescue
  puts '*'*50
  puts 'Error reading values from SBTM.YML!'
  puts 'Please check to make sure all required values exist.'
  puts '*'*50
  exit
end

# Check to make sure the tester ID is not empty:
if ( tester_info['full name'].nil? ) or ( tester_info['initials'].nil? ) or
  ( tester_info['initials'].length < 2 ) or ( tester_info['initials'].length > 3 ) 
  
  puts '*'*50
  puts 'SBTM.YML needs to be updated!'
  puts 'Please update the Tester ID section with your full name and initials'
  puts "'full name' = '#{ tester_info['full name'] }'"
  print "'initials'  = '#{ tester_info['initials'] }'" 
  
  inits = 0
  inits = tester_info['initials'].length unless tester_info['initials'].nil?
  if ( inits < 2 ) or ( inits > 3 )
    print " (Must be 2 or 3 letters)\n"
  else
    print " (ok)\n"
  end
  
  puts '*'*50
  exit
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
mainbody << Time.now.strftime("%m/%d/%Y %H:%M\n\n")

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


# Look for previous sessions by this tester to figure out what the next session sheet label should be

next_letter = 'a'
previous_files = []
filename_template = "/et-#{ tester_info['initials'].downcase }-*.ses"

previous_files << Dir[ approved_folder + filename_template ] + Dir[ submitted_folder + filename_template ] 
previous_files.flatten!

unless previous_files.empty?
  # ( Regex recap: $1 = yy, $2 = mm, $3 = dd, $4 = letter )
  previous_files.sort.last.downcase =~ /-(\d\d)(\d\d)(\d\d)-(\w)\./
  next_letter = $4.next if ( Time.now.strftime("%y%m%d") == ( $1 + $2 + $3 ) )
end


# Create the file - in the Submitted folder:

new_et_session_name = "et-#{ tester_info['initials'].downcase }-#{ Time.now.strftime("%y%m%d") }-#{ next_letter }.ses"

et_file =  File.new( submitted_folder + '/' + new_et_session_name,  'w' )
et_file.puts mainbody
et_file.close

### END ###