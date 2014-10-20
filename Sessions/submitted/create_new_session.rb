#! /usr/bin/env ruby
# -----
# create_new_session.rb
#
# Purpose: Create a new empty ET session sheet. Use the required sections in 
# SBT_CONFIG.YML and the latest found sheet to create the next one.
#
# Command Line Options : None. The script will move up through the folder tree
# looking for the following sub-directories:
# 1. 'config' folder containing the SBT_CONFIG.YML configuration file
#    (to read the tester information - name & initials)
#    (also the location of the optional footer text file)
# 2. 'approved' folder
# 3. 'submitted' folder (default location for writing the new session sheet to)
#
# [NOTE:]  IF there is a file in the 'config' folder called "dont-include.footer.txt",
#          the text in that file will be automatically appended to the session
#          sheet created here.
#
# [NOTE:] The last step in this script is to *launch* the new file by issuing a
#         system command. This script uses standard system calls to default
#         text editors. Please update the "operating_system_check" method below
#         with the appropriate command for your system or needs.
#         (i.e. whatever you would type at a command prompt to launch the new file
#          in a text editor of your choice.)
#
# -----
# Copyright (C) 2014 Paul Carvalho
#
# This program is free software and is distributed under the same terms as the Ruby GPL.
# See LICENSE.txt in the 'doc' folder for more information.
#
# Last Updated:: 19 October 2014
# -----

require 'yaml'

class CreateSessionSheet

  ##
  # Exit gracefully and show a message indicating what failed. The 'message' parameter is an array.
  #
  def setup_fail(message)
    puts '-'*50
    message.each { |line| puts line }
    puts '-'*50
    exit
  end

  def exit_missing_config_folder
    message = []
    message << "Warning! Could not find the 'config' directory!"
    message << "Please place this '#{File.basename($0)}' in a sub-directory of 'Sessions'"
    setup_fail message
  end

  def exit_missing_config_file
    message = []
    message << 'Problem Found! Unable to find the SBT_CONFIG.YML configuration file!'
    message << "Please ensure the 'config' directory contains the SBT_CONFIG.YML file"
    setup_fail message
  end

  def exit_invalid_sheet_location(folder)
    message = []
    message << "'#{ folder }' is not a valid directory!"
    message << 'Please check the name specified and try again.'
    setup_fail message
  end

  def initialize
    ## SPECIFY THE DATE/TIME FORMAT YOU WANT TO SEE IN
    ## YOUR SESSION SHEETS IN THE "SBT_CONFIG.YML" CONFIG FILE

    ## CHANGE THESE FOLDER NAMES IF YOUR LOCATIONS ARE DIFFERENT
    @approved_folder = 'approved'
    @submitted_folder = 'submitted'

    # Find the 'config' folder location; keep moving up the folder tree from the current script location:
    Dir.chdir(File.expand_path(File.dirname(__FILE__)))
    Dir.chdir('..') while (not Dir.entries('.').include? 'config') and (Dir.pwd !~ /\/$/)

    # Check the folders:
    exit_missing_config_folder unless Dir.entries('.').include? 'config'
    exit_missing_config_file unless File.exist?('config/sbt_config.yml')

    [@approved_folder, @submitted_folder].each do |folder|
      folder.gsub!('\\', '/') # (make sure the /s are forward)
      exit_invalid_sheet_location(folder) unless FileTest.directory?(folder)
      folder << '/' if folder[-1, 1] != '/'
    end
  end

  def check_config_settings
    message = []

    begin
      # Read the Configuration file:
      config = YAML.load_file('config/sbt_config.yml')
      @footer_filename = 'config/include.footer.txt'

      @tester_info = config['tester_ID']
      @include_switch = config['scan_options']
      @output = config['output']
      @include_footer = false

      raise if @tester_info.nil? or @include_switch.nil? or @output.nil?
    rescue
      message << 'Error reading values from SBT_CONFIG.YML!'
      message << 'Please check to make sure all required values exist.'
      setup_fail(message)
    end

    # Check to make sure the tester info is not empty:
    if (@tester_info['full name'].nil?) or (@tester_info['initials'].nil?) or
        (@tester_info['initials'].length < 2) or (@tester_info['initials'].length > 3)

      message << 'SBT_CONFIG.YML needs to be updated!'
      message << 'Please update the Tester ID section with your full name and initials'
      message << "'full name' = '#{ @tester_info['full name'] }'"

      init_string = "'initials'  = '#{ @tester_info['initials'] }'"
      init_length = 0
      init_length = @tester_info['initials'].length unless @tester_info['initials'].nil?
      init_string += ' <-- Must be 2 or 3 letters' if (init_length < 2) or (init_length > 3)
      message << init_string

      setup_fail(message)
    end

    # Check to make sure the Date & Time formats are present:
    if (@output['date format'].nil?) or (@output['time format'].nil?)
      # (it would be nice to add a regex here to check for basic expected formatting)

      message << 'SBT_CONFIG.YML needs to be updated!'
      message << 'Please update the Output section with the Date and Time formats'
      message << "'date format' = '#{ @output['date format'] }'"
      message << "'time format' = '#{ @output['time format'] }'"
      setup_fail(message)
    end

    # Append extra text to the bottom of the session sheet if "dont-include.footer.txt" exists.
    if FileTest.exist?( @footer_filename )
      # NOTE: the first text line in the footer file needs to be the 'coffee break' line (i.e. "-- c[_] --")
      # otherwise the SCAN tool will *not* like the extra text you add!
      # (see Sessions/doc/session_sheet_template.ses for example)
      # IO.readlines('config/dont-include.footer.txt').join

      footer_content = File.open( @footer_filename )
      if footer_content.gets =~ /-- c\[_\] --/
        @include_footer = true
      else
        message << "'#{@footer_filename}' file found but missing separator on line 1."
        message << "Please see correct expected line in 'doc/session_sheet_template.ses'"
        setup_fail(message)
      end
      footer_content.close
    end

  end

  def create_sheet_content
    # Create main body of the template
    mainbody = []
    dashedline = '-' * 50

    mainbody << 'CHARTER'
    mainbody << dashedline
    mainbody << '' << ''

    if @include_switch['LTTD']
      mainbody << '#LTTD_AREA'
      mainbody << '' << ''
    end

    if @include_switch['Areas']
      mainbody << '#AREAS'
      mainbody << '' << ''
    end

    if @include_switch['Build']
      mainbody << '#BUILD'
      mainbody << '' << ''
    end

    mainbody << 'START'
    mainbody << dashedline
    # Add time stamp here!
    datetime_format = @output['date format'] + ' ' + @output['time format']
    mainbody << Time.now.strftime(datetime_format)
    mainbody << ''

    mainbody << 'TESTER'
    mainbody << dashedline
    # Add Tester Name here!
    # (NOTE: only the primary tester name is added here. Add more tester names manually)
    mainbody << @tester_info['full name']
    mainbody << ''

    if @include_switch['Duration'] or @include_switch['TBS'] or @include_switch['C vs O']
      mainbody << 'TASK BREAKDOWN'
      mainbody << dashedline
      if @include_switch['Duration']
        mainbody << '#DURATION'
        mainbody << '' << ''
      end
      if @include_switch['TBS']
        mainbody << '#SESSION SETUP'
        mainbody << '' << ''
        mainbody << '#TEST DESIGN AND EXECUTION'
        mainbody << '' << ''
        mainbody << '#BUG INVESTIGATION AND REPORTING'
        mainbody << '' << ''
      end
      if @include_switch['C vs O']
        mainbody << '#CHARTER VS. OPPORTUNITY'
        mainbody << '100/0'
        mainbody << ''
      end
    end
    if @include_switch['Data Files']
      mainbody << 'DATA FILES'
      mainbody << dashedline
      mainbody << '#N/A'
      mainbody << ''
    end
    mainbody << 'TEST NOTES'
    mainbody << dashedline
    mainbody << '' << '' << '' << ''

    mainbody << 'BUGS'
    mainbody << dashedline
    mainbody << '#N/A'
    mainbody << ''

    mainbody << 'ISSUES'
    mainbody << dashedline
    mainbody << '#N/A'
    mainbody << ''

    if @include_footer
      # mainbody << IO.readlines('config/dont-include.footer.txt').join ## <- do we need this join?? ***
      mainbody << IO.readlines( @footer_filename )
    end

    mainbody
  end

  def create_filename
    # Look for previous sessions by this tester to figure out what the next session sheet label should be
    next_letter = 'a'
    previous_files = []
    filename_template = "et-#{ @tester_info['initials'].downcase }-*.ses"

    previous_files << Dir[@approved_folder + filename_template] + Dir[@submitted_folder + filename_template]
    previous_files.flatten!

    unless previous_files.empty?
      # ( Regex recap: $1 = yymmdd, $2 = single letter )
      previous_files.sort.last.downcase =~ /-(\d{6})-(\w)\./
      next_letter = $2.next if (Time.now.strftime("%y%m%d") == $1)
    end

    "et-#{ @tester_info['initials'].downcase }-#{ Time.now.strftime("%y%m%d") }-#{ next_letter }.ses"
  end

  def operating_system_check
    case RUBY_PLATFORM
      when /mswin|windows|cygwin|mingw32/i
        # very likely Windows - (assumes the system has a file association for .SES files)
        'start '
      when /linux/i
        # very likely linux
        'gedit '
      else
        # assuming it's Max OS X
        'open -e '
    end
  end

  def run
    check_config_settings
    mainbody = create_sheet_content
    new_et_session_name = create_filename

    File.open(@submitted_folder + new_et_session_name, 'w') do |et_file|
      mainbody.each { |line| et_file.puts line }
    end

    puts "\n** Created new file: " + @submitted_folder + new_et_session_name

    # Launch the new session sheet created:
    launch_command = operating_system_check
    system(launch_command + @submitted_folder + new_et_session_name)
  end

end

CreateSessionSheet.new.run

### END ###