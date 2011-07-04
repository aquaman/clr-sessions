#! /usr/bin/env ruby
# -----
# scan2.rb
#
# Purpose:
# 1. to check each *.SES file in the specified directory for structure and missing elements, and
# 2. to generate data files that capture certain metrics
#
# Command Line Options : 2 Required:
# 1. folder location of the SBTM.YML configuration file
# 2. folder location of the .SES files to scan
#
# Here are some examples:
# * run from the parent "Sessions" folder:
#    bin\scan.rb config approved
# * you may specify absolute path names if you prefer:
#    c:\sessions\bin\scan.rb c:\sessions\config c:\sessions\submitted
#
# -----
# Author:: Paul Carvalho
# Last Updated:: 04 July 2011
# Version:: 2.2
# -----
@ScriptName = File.basename($0)

if ( ARGV.length < 2 ) or ! File.exist?( ARGV[0] + '/sbtm.yml' ) or ! FileTest.directory?( ARGV[1] )
  puts "\n!! Invalid or incorrect number of command line arguments specified."
  puts "\nUsage: #{@ScriptName} config_dir folder_to_scan"
  puts "\nWhere:"
  puts "* config_dir     = the path to the directory containing SBTM.YML"
  puts "* folder_to_scan = the path to the directory containing the session sheets\n"
  exit
end

# Load Ruby libraries - YAML, Date and Time
require 'yaml'
require 'date'
require 'time'

# Read the Configuration file:
config_dir = ARGV[0]
scan_dir = ARGV[1]
config = YAML.load_file( config_dir + '/sbtm.yml' )

begin
  @data_dir = config['folders']['data_dir']
  metrics_dir = config['folders']['metrics_dir']
  
  logfile = config['output']['logfile']
  
  @timebox = config['timebox']
  @include_switch = config['scan_options']
  
  raise if @data_dir.nil? or metrics_dir.nil? or @timebox.nil? or @include_switch.nil?
rescue
  puts '*'*50
  puts 'Error reading value from SBTM.YML!'
  puts '*'*50
  exit
end

# CHECK that the file directories specified appear to be valid:
[ @data_dir, metrics_dir ].each do |folder|
  unless FileTest.directory?( folder )
    puts '*'*50
    puts "'" + folder + "' is not a valid directory!" 
    puts "Please check the name specified in SBTM.YML and try again."
    puts '*'*50
    exit
  end
end

# CHECK for the Log file argument and check for valid filename chars if given
if logfile.nil?
  @outfile = NIL
else
  logfile = '' if logfile =~ /^\./    # Don't start a filename with a dot!
  logfile.gsub!( /[?:*"<>|]/, '')   # Remove some unwanted filename characters just in case they show up.
  if logfile.empty?
    puts '!! Invalid filename specified for the logfile in SBTM.YML.  Outputting to console...'
    @outfile = NIL
  else
    @outfile = File.new( logfile, 'w' )
  end
end

# Set the TASK BREAKDOWN switch if one of the sub-sections are included:
if (@include_switch['Duration'] or @include_switch['TBS'] or @include_switch['C vs O'])
  @include_switch['Task'] = true
else
  @include_switch['Task'] = false
end


### METHODS ###

##
# Exit the script gracefully if it encounters a problem trying to open a file.
#
# Print a friendly message and include the script line number where it failed.
#
# <em>(This is kind of an ugly method. It is a carry-over from the original PERL script and not very graceful/Ruby'ish.)</em>
#
def die( parting_thought, line_num )
  msg = @ScriptName + ": " + parting_thought + ": line ##{line_num}"
  puts  msg
  @outfile.puts msg unless @outfile.nil?
  exit
end

##
# Print the error message encountered during the scan.
#
# The output may be to console or to log file. This is set in the SBTM.YML file.
#
def error( message )
  @errors_found = true
  output( '### Error : ' + @file.sub("/", "\\") + ' : ' + message )
  output( '' )
end

##
# Print any warning messages that are found. These don't trigger the "Errors Found!" message.  A Warning message alone will still produce the "Your papers are in order" message.
#
# Warning messages may be enabled/disabled via the SBTM.YML configuration file.
#
def warning( message )
  if @include_switch['Warnings']
    output( '** WARNING : ' + @file.sub("/", "\\") + ' : ' + message )
    output( '' )
  end
end

##
# Print the specified message either to file or to the console.
#
# The SBTM.YML configuration file contains an "output" setting for the "logfile":
# * if the setting value is blank, all output messages will go to the console
# * otherwise, output will go to the filename specified
#
def output( message )
  if @outfile.nil?
    puts message
  else
    @outfile.puts message
  end
  $stdout.flush
end

##
# This is a 'clean up' method. It removes trailing spaces and blank lines from the end of text block sections in the session sheets.
#
def clear_final_blanks( working_array )
  unless working_array.empty?
    working_array.size.times do
      working_array.pop if working_array.last.strip.empty?
    end
    working_array.last.chomp!
    
    return working_array
  end
end

##
# This is the starting point for examining each session sheet. Review each sheet and break it up into the major sections. Put the contents of each section block into an array so we can work with it later.
#
def parse_file
  
  content_found = Hash.new
  content_found.default = false
  @charter_contents = []
  @start_contents = []
  @tester_contents = []
  @breakdown_contents = []
  @data_contents = []
  @testnotes_contents = []
  @bugs_contents = []
  @issues_contents = []

  f_SESSION = File.open( @file ) rescue die( "Can't open #{@file}", __LINE__ )
  
  while ( line = f_SESSION.gets )
    
    # Stop scanning if you encounter 'coffee break' line
    # (if this appears anywhere, it should appear at the bottom, *after* all required sections are found)
    break if line.strip =~ /^-+\s+c\[_\]\s+-+$/
    
    # NOTE: These session sheet section headings *must* be in all CAPS.
    if ( line =~ /^CHARTER/)
      error("More than one CHARTER section found")  if ( content_found['charter'] )
      line = f_SESSION.gets     # automatically skip the next line (should be dashed line)
      content_found['charter'] = true
      reference_array = @charter_contents
      next
    elsif ( line =~ /^START/)
      error("More than one START section found")  if ( content_found['start'] )
      line = f_SESSION.gets
      content_found['start'] = true
      reference_array = @start_contents
      next
    elsif ( line =~ /^TESTER/)
      error("More than one TESTER section found")  if ( content_found['tester'] )
      line = f_SESSION.gets
      content_found['tester'] = true
      reference_array = @tester_contents
      next
    elsif ( line =~ /^TASK BREAKDOWN/)
      # Separate out any content found here even if @include_switch['Task'] = false
      # this will make sure that this content doesn't mistakenly get added to the section above in the session sheet.
      
      error("More than one TASK BREAKDOWN section found")  if ( content_found['breakdown'] )
      line = f_SESSION.gets
      content_found['breakdown'] = true
      reference_array = @breakdown_contents
      
      warning("TASK BREAKDOWN section found but skipped in SCAN based on SBTM.YML config.") unless @include_switch['Task']
      next
    elsif ( line =~ /^DATA FILES/)
      # Separate out any content found here even if @include_switch['Data Files'] = false
      # this will make sure that this content doesn't mistakenly get added to the section above in the session sheet.
      
      error("More than one DATA FILES section")  if ( content_found['data'] )
      line = f_SESSION.gets
      content_found['data'] = true
      reference_array = @data_contents
      
      warning("DATA FILES section found but skipped in SCAN based on SBTM.YML config.") unless @include_switch['Data Files']
      
      next
    elsif ( line =~ /^TEST NOTES/)
      error("More than one TEST NOTES section found")  if ( content_found['notes'] )
      line = f_SESSION.gets
      content_found['notes'] = true
      reference_array = @testnotes_contents
      next
    elsif ( line =~ /^BUGS/)
      error("More than one BUGS section found")  if ( content_found['bugs'] )
      line = f_SESSION.gets
      content_found['bugs'] = true
      reference_array = @bugs_contents
      next
    elsif ( line =~ /^ISSUES/)
      error("More than one ISSUES section found")  if ( content_found['issues'] )
      line = f_SESSION.gets
      content_found['issues'] = true
      reference_array = @issues_contents
      next
    end
    line.gsub!('"', "'") if line.include? '"'
    reference_array << line rescue true   # (Rescue in case there are blank lines at the start of the file and the reference_array variable isn't set yet)
    content_found['tab_char'] = true if ( line =~ /\t/)
  end
  
  error("Missing a CHARTER section") unless content_found['charter']
  error("Missing a START section") unless content_found['start']
  error("Missing a TESTER section") unless content_found['tester']
  error("Missing a TASK BREAKDOWN section") if @include_switch['Task'] and ! content_found['breakdown']
  error("Missing a DATA FILES section") if @include_switch['Data Files'] and ! content_found['data']
  error("Missing a TEST NOTES section") unless content_found['notes']
  error("Missing a BUGS section") unless content_found['bugs']
  error("Missing an ISSUES section") unless content_found['issues']
  warning("[Tab] character found in file.  Tabs may cause unexpected formatting in " +
    "different editors.  Please convert Tabs to Spaces if possible.") if content_found['tab_char']
  
  # (leave only the section info in the returning array)
  content_found.delete 'tab_char'
  return content_found
end

##
# Examine the contents of the TESTER section of the session sheet.
#
# Output:
# * the names of the testers found in each session sheet are immediately saved to file
# * the total number of testers in the section are returned
#
def parse_tester
  testers_found = []
  
  @tester_contents.delete_if {|x| x.strip.empty? }     # (Clear out the blank lines)
  
  @tester_contents.each do |name|
    name.strip!
    if ( name =~ /\w+/ )
      @f_TESTERS.puts '"' + File.basename(@file) + "\"\t\"#{name}\""
      testers_found << name
    end
  end
  error("Missing tester name in TESTER section") if testers_found.empty?
  
  return testers_found
end

##
# Examine the contents of the CHARTER section of the session sheet.
#
# This method performs different error checks depending on the _session_type_ -- which may be set to either "test" or "todo" depending on the type of sheet scanned.
#
# There are three optional sub-sections that may appear here:
# * ##LTTD_AREA
# * ##AREAS
# * ##BUILD
# The sub-sections may be enabled in the SBTML.YML configuration file.
#
# Output:
# * Charter text is immediately saved to file
# * Build ID text, if present in the session sheet, is immediately saved to file
#
def parse_charter( session_type = 'test' )
  charter_complete = false ;  charter_desc = []
  lttd_found = false ;        lttd_area = []
  area_found = false ;        areas = []
  build_found = false ;       build_info = []
  in_section = ''
  build_line_found = false
  strategy_line_found = false
  os_line_found = false
  
  @charter_contents.delete_if {|x| x.strip.empty? }

  @charter_contents.each do |line|
    
    line.strip!
    if line =~ /^#AREAS/
      if @include_switch['Areas']
        error('More than one #AREAS hashtag found in CHARTER section') if ( area_found )
        area_found = true
        in_section = 'AREA'
      else
        warning("#AREAS hashtag found but skipped in SCAN based on SBTM.YML config.")
      end
      
    elsif line =~ /^#LTTD_AREA/
      if @include_switch['LTTD']
        error('More than one #LTTD_AREA hashtag found in CHARTER section') if ( lttd_found )
        lttd_found = true
        in_section = 'LTTD'
      else
        warning("#LTTD_AREA hashtag found but skipped in SCAN based on SBTM.YML config.")
      end
      
    elsif line =~ /^#BUILD/
      if @include_switch['Build']
        error('More than one #BUILD hashtag found in CHARTER section') if ( build_found )
        build_found = true
        in_section = 'BUILD'
      else
        warning("#BUILD hashtag found but skipped in SCAN based on SBTM.YML config.")
      end
      
    end
    
    if ( ! charter_complete )
      charter_desc << line unless ( line =~ /^#/ ) or ( lttd_found ) or ( area_found ) or ( build_found )
      
      if ( line =~ /^#/ )
        charter_complete = true
        if ( ! charter_desc.empty? )
          clear_final_blanks( charter_desc )
          @f_CHARTERS.print '"' + File.basename(@file) + "\"\t\"DESCRIPTION\"\t\""
          charter_desc.each {|x| @f_CHARTERS.print x }
          @f_CHARTERS.print "\"\n"
        else
          error('No charter description was given in CHARTER section')
        end
      end
      
    elsif ( ! lttd_found ) and ( ! area_found ) and ( ! build_found ) and ( line !~ /^#/ )
      error("Unexpected text \"#{line.chomp}\" found in CHARTER section. The charter description ends " + 
        "when '#' starts a new line. All other text in the CHARTER section must be preceded by a valid '#' hashtag.")
      
    end
    
    next if line =~ /^#/
    
    case in_section
    when 'LTTD'
      line.upcase!
      if @LTTD_Areas.include?( line )
        lttd_area << line unless lttd_area.include?( line )     # (skip duplicates)
      else
        error("Unexpected #LTTD_AREA label \"#{line}\" in CHARTER section. Ensure that label exists in LTTD_AREAS.INI.")
      end
    
    when 'AREA'
      line.upcase!
      build_line_found = true if ( line =~ /^BUILD/ )     # (Hard-coded this keyword to be the *minimum* requirement for the #AREAS section)
      strategy_line_found = true if ( line =~ /STRATEGY/ )     # (Sessions should always have a Strategy too)
      
      if @areas_list.include?( line )
        areas << line unless areas.include?( line )     # (skip duplicates)
      else
        error("Unexpected #AREAS label \"#{line}\" in CHARTER section. Ensure that label exists in COVERAGE.INI.")
      end
    
    when 'BUILD'
      build_line_found = true
      build_info << line
      # Q: Is there an *unexpected* content you might find in this section?  Should it only be one line?  Error if there are 2 lines?
      # NOTE: currently allowing free-form text in this section. Multiple lines/ID's allowed.
      # ASSUMPTION: Build ID = single-line identifier of the build you tested on during the test session.
      
    end
  end
  
  if ( ! charter_desc.empty? ) and ( ! charter_complete )
    charter_complete = true
    clear_final_blanks( charter_desc )
    @f_CHARTERS.print '"' + File.basename(@file) + "\"\t\"DESCRIPTION\"\t\""
    charter_desc.each {|x| @f_CHARTERS.print x }
    @f_CHARTERS.print "\"\n"
  end
  
  if ( lttd_found and ! lttd_area.empty? )
    lttd_area.each do |line|
      @f_CHARTERS.puts '"' + File.basename(@file) + "\"\t\"LTTD AREA\"\t\"#{line}\""
    end
  end
  
  if ( area_found and ! areas.empty? )
    areas.each do |line|
      @f_CHARTERS.puts '"' + File.basename(@file) + "\"\t\"AREA\"\t\"#{line}\""
    end
  end
  
  if ( build_found and ! build_info.empty? )
    build_info.each do |line|
      @f_CHARTERS.puts '"' + File.basename(@file) + "\"\t\"BUILD\"\t\"#{line}\""
      @f_BUILD.puts '"' + File.basename(@file) + "\"\t\"#{line}\""
    end
  end
  
  error('Missing charter description in CHARTER section.') unless ( charter_complete )
  
  error('Missing #LTTD_AREA value in CHARTER section. Ensure the #LTTD_AREA hashtag ' +
    'is present and has valid area values underneath.') if @include_switch['LTTD']  and ( ! lttd_found or  lttd_area.empty? )
  
  error('Missing #AREAS values in CHARTER section. Ensure the #AREAS hashtag is present ' +
    'and has valid area values underneath.') if @include_switch['Areas'] and ( ! area_found or areas.empty? )
  
  error('Missing #BUILD value in CHARTER section. Ensure the #BUILD hashtag is present ' +
    'and has valid information underneath.') if @include_switch['Build'] and ( ! build_found or build_info.empty? )
  
  unless session_type == 'todo'
    error("Missing 'BUILD' line in the #AREAS section.  Please add it.") if @include_switch['Areas'] and ! @include_switch['Build'] and ! build_line_found
    
    error("Missing 'STRATEGY' line in the #AREAS section.  Please add it.") if @include_switch['Areas'] and ! strategy_line_found
  end
end

##
# Examine the contents of the START section of the session sheet.
#
# This method performs different error checks depending on the _session_type_ -- which may be set to either "test" or "todo" depending on the type of sheet scanned.
#
# Output:
# * start date, time, and an integer representation of date+time are returned
#
def parse_start( session_type = 'test' )
  time_found = false
  fn_day = ''
  fn_month = ''
  fn_year = ''
  time_line = 0

  File.basename( @file ) =~ /-(\d\d)(\d\d)(\d\d)-/
  fn_year = $1
  fn_month = $2.to_i
  fn_day = $3.to_i
  
  @start_contents.delete_if {|x| x.strip.empty? }
  @start_contents.each do |line|
    line.strip!
    if (line =~ /(\d+)\/(\d+)\/(\d{2,4})\s+(.+)/)
      # create a Time object to work with:
      # reference: $1 = month, $2 = day, $3 = year, $4 = time stamp
      # ASSUMPTION ALERT: This date conversion has a defined format of mm/dd/yy
      # Time.parse method needs date format in yyyy-mm-dd format to work correctly with all versions of Ruby
      time_line = Time.parse( "#{$3}-#{$1}-#{$2} #{$4}" )
      
      if ( time_found )
        error('Multiple time stamps detected in START section')
      else
        time_found = true
        
        if ((( time_line.mon != fn_month ) or ( time_line.day != fn_day) or ( time_line.strftime("%y") != fn_year )) and session_type == 'test' )
          error('File name does not match date in START section')
        end
      end
    elsif ( ! line.empty? )
      error("Unexpected text found \"#{line}\" in START section. Ensure that the time stamp " +
        "is in this format: mm/dd/yyyy hh:mm{am|pm}. 12-hr or 24-hr time format works.")
    end
  end
  
  error('Missing time stamp in START section') if (! time_found && session_type == 'test' )
  
  error('START section must be empty if the sheet is named as a TODO. Did you forget ' +
    'to rename the session sheet?') if ( time_found && session_type == 'todo' )
  
  return time_line
end

##
# Examine the contents of the TASK BREAKDOWN section of the session sheet. The contents of this section are used to generate session metrics.
#
# There are five optional sub-sections that may appear here:
# * ##DURATION
# * ##TEST DESIGN AND EXECUTION
# * ##BUG INVESTIGATION AND REPORTING
# * ##SESSION SETUP
# * ##CHARTER VS. OPPORTUNITY
# The sub-sections may be enabled in the SBTML.YML configuration file. The (1) Test Design, (2) Bug Investigation, and (3) Session Setup sections are configured as a *set* via the 'TBS' setting.
#
# Output:
# * raw values for: duration, charter, opportunity, test, bug investigation and setup percentages
# * several calculations using combinations of the above along with the number of testers in a given session
#
def parse_breakdown( num_testers )
  dur_section_found = false ;  dur_content_found = false
  tde_section_found = false ;  tde_content_found = false
  bir_section_found = false ;  bir_content_found = false
  set_section_found = false ;  set_content_found = false
  cvo_section_found = false ;  cvo_content_found = false
  
  in_section = ''
  dur_val = ''
  dur_times = ''
  test_val = '0'
  bug_val = '0'
  prep_val = '0'
  cha_val = '0'
  opp_val = '0'
    
  @breakdown_contents.delete_if {|x| x.strip.empty? }
  @breakdown_contents.each do |line|
    line.strip!
    
    case line
    when /^#DURATION/
      if @include_switch['Duration']
        error('More than one #DURATION hashtag found in TASK BREAKDOWN section') if ( dur_section_found )
        dur_section_found = true
        in_section = 'DUR'
      else
        warning('#DURATION hashtag found but skipped in SCAN based on SBTM.YML config.')
      end
      next
    when /^#TEST DESIGN AND EXECUTION/
      if @include_switch['TBS']
        error('More than one #TEST DESIGN AND EXECUTION hashtag found in TASK BREAKDOWN section') if ( tde_section_found )
        tde_section_found = true
        in_section = 'TDE'
      else
        warning('#TEST DESIGN AND EXECUTION hashtag found but skipped in SCAN based on SBTM.YML config.')
      end
      next
    when /^#BUG INVESTIGATION AND REPORTING/
      if @include_switch['TBS']
        error('More than one #BUG INVESTIGATION AND REPORTING hashtag found in TASK BREAKDOWN section') if ( bir_section_found )
        bir_section_found = true
        in_section = 'BIR'
      else
        warning('#BUG INVESTIGATION AND REPORTING hashtag found but skipped in SCAN based on SBTM.YML config.')
      end
      next
    when /^#SESSION SETUP/
      if @include_switch['TBS']
        error('More than one #SESSION SETUP hashtag found in TASK BREAKDOWN section') if ( set_section_found )
        set_section_found = true
        in_section = 'SET'
      else
        warning('#SESSION SETUP hashtag found but skipped in SCAN based on SBTM.YML config.')
      end
      next
    when /^#CHARTER VS. OPPORTUNITY/
      if @include_switch['C vs O']
        error('More than one #CHARTER VS. OPPORTUNITY hashtag found in TASK BREAKDOWN section') if ( cvo_section_found )
        cvo_section_found = true
        in_section = 'CVO'
      else
        warning('#CHARTER VS. OPPORTUNITY hashtag found but skipped in SCAN based on SBTM.YML config.')
      end
      next
    end
      
    case in_section
    when 'DUR'
      if ( ! dur_content_found )
        dur_content_found = true
        
        (dur_val, dur_times) = line.split('*')
        dur_val.strip!
        dur_val.downcase!
        
        if ( dur_times.nil? ) or ( dur_times.strip.empty? )
          dur_times = '1'
        else
          dur_times.strip!
        end
        
        unless ( dur_val.eql?('short') or dur_val.eql?('normal') or dur_val.eql?('long') )
          error("Unexpected #DURATION value \"#{dur_val}\" in TASK BREAKDOWN section. Legal values are: short, normal, or long")
        end
        unless ( dur_times == dur_times.to_i.to_s and dur_times.to_i > 0 ) or ( dur_times == dur_times.to_f.to_s and dur_times.to_f > 0.0 )
          error("Unexpected #DURATION multiplier \"#{dur_times}\" in TASK BREAKDOWN section. Must be a positive integer or decimal value.")
        end
      else
        error("Unexpected value encountered under #DURATION in the TASK BREAKDOWN section: \"#{line}\"")
      end
      
    when 'TDE'
      if ( ! tde_content_found )
        tde_content_found = true
        
        test_val = line
        if ( test_val.to_i < 0 or test_val.to_i > 100 ) or ( line =~ /\D+/ )
          error('Unexpected #TEST DESIGN AND EXECUTION value in TASK BREAKDOWN section. Ensure that the value is an integer from 0-100.')
        end
      else
        error("Unexpected value encountered under #TEST DESIGN AND EXECUTION in the TASK BREAKDOWN section: \"#{line}\"" )
      end
      
    when 'BIR'
      if ( ! bir_content_found )
        bir_content_found = true
        
        bug_val = line
        if ( bug_val.to_i < 0 or bug_val.to_i > 100) or ( line =~ /\D+/ )
          error('Unexpected #BUG INVESTIGATION AND REPORTING value in TASK BREAKDOWN section. Ensure that the value is an integer from 0-100.')
        end
      else
        error("Unexpected value encountered under #BUG INVESTIGATION AND REPORTING in the TASK BREAKDOWN section: \"#{line}\"")
      end
      
    when 'SET'
      if ( ! set_content_found )
        set_content_found = true
        
        prep_val = line
        if ( prep_val.to_i < 0 or prep_val.to_i > 100) or ( line =~ /\D+/ )
          error('Unexpected #SESSION SETUP value in TASK BREAKDOWN section. Ensure that the value is an integer from 0-100.')
        end
      else
        error("Unexpected value encountered under #SESSION SETUP in the TASK BREAKDOWN section: \"#{line}\"")
      end
      
    when 'CVO'
      if ( ! cvo_content_found )
        cvo_content_found = true
        
        if ( line !~ /^\d+\s*(\W)\s*\d+/ )
          error("Unexpected #CHARTER VS. OPPORTUNITY value \"#{line}\" in TASK BREAKDOWN section. " +
            "Ensure that the values are integers from 0-100 separated by '/'.")
        end
        
        (cha_val, opp_val) = line.split($1)
        
        if cha_val.nil?
          cha_val = '0'
        else
          cha_val.strip!
          cha_val = '0' if ( cha_val.empty? )
        end
        if opp_val.nil?
          opp_val = '0'
        else
          opp_val.strip!
          opp_val = '0' if ( opp_val.empty? )
        end
        
        unless ( ( cha_val.to_i + opp_val.to_i ) == 100 )
          error('#CHARTER VS. OPPORTUNITY value does not add up to 100 in TASK BREAKDOWN section')
        end
      else
        error("Unexpected value encountered under #CHARTER VS. OPPORTUNITY in the TASK BREAKDOWN section: \"#{line}\"")
      end
    end
  end
  
  error('Missing #DURATION in TASK BREAKDOWN section') if @include_switch['Duration'] and ( ( ! dur_section_found ) or ( dur_section_found and ! dur_content_found) )
  
  error('Missing #TEST DESIGN AND EXECUTION in TASK BREAKDOWN section') if @include_switch['TBS'] and ( ( ! tde_section_found ) or ( tde_section_found and ! tde_content_found) )
  
  error('Missing #BUG INVESTIGATION AND REPORTING in TASK BREAKDOWN section') if @include_switch['TBS'] and ( ( ! bir_section_found ) or ( bir_section_found and ! bir_content_found) )
  
  error('Missing #SESSION SETUP in TASK BREAKDOWN section') if @include_switch['TBS'] and ( ( ! set_section_found ) or ( set_section_found and ! set_content_found) )
  
  error('Missing #CHARTER VS. OPPORTUNITY in TASK BREAKDOWN section') if @include_switch['C vs O'] and ( ( ! cvo_section_found ) or ( cvo_section_found and ! cvo_content_found) )
  
  if @include_switch['TBS'] and ( ( prep_val.to_i + test_val.to_i + bug_val.to_i ) != 100 )
    error('Unexpected sum of TASK BREAKDOWN values. Values of #SESSION SETUP, #TEST DESIGN AND EXECUTION, and #BUG INVESTIGATION AND REPORTING must add up to 100')
  end
  
  if @include_switch['Duration']
    if ( dur_val == 'long' ) 
      dur_val = ( ( @timebox['long'].to_f / @timebox['normal'].to_f ) * dur_times.to_f ).to_s
    elsif ( dur_val == 'normal' ) 
      dur_val = dur_times
    else 
      dur_val = ( ( @timebox['short'].to_f / @timebox['normal'].to_f ) * dur_times.to_f ).to_s
    end
    n_total = (dur_val.to_f * num_testers)
  else
    dur_val = '0'
    n_total = 1.0   # (use this float value for calculations but not for the actual "N Total" value)
  end
  
  if @include_switch['C vs O']
    n_charter = (cha_val.to_f / 100)
  else
    n_charter = 1.0
  end
  
  return dur_val, cha_val, opp_val, test_val, bug_val, prep_val, 
    (dur_val.to_f * num_testers), 
    (n_total * cha_val.to_i / 100), 
    (n_total * opp_val.to_i / 100), 
    (n_total * test_val.to_i / 100 * n_charter), 
    (n_total * bug_val.to_i / 100 * n_charter), 
    (n_total * prep_val.to_i / 100 * n_charter)
  
end

##
# Examine the contents of the DATA FILES section of the session sheet.
#
# This section may be included or excluded via the SBTML.YML configuration file.
#
# Output:
# * the Data File names are immediately saved to file if they are found to exist in the "data_dir" location specified in the SBTML.YML configuration file
#
def parse_data
  na = false
  content = false
  
  @data_contents.delete_if {|x| x.strip.empty? }
  
  @data_contents.each do |line|
    line.strip!
    if ( line =~ /^#N\/A/i )
      na = true
    elsif ( line =~ /\w+/ )
      content = true
    end
  end
  
  if ( ! na and ! content )
    error('DATA FILES section is empty. If you used no data files in this test session, specify #N/A.')
    
  elsif ( na and content )
    error('Unexpected text found with #N/A tag in DATA FILES section. If you specify #N/A, no other text is permitted in this section.')
    
  elsif ( na and ! content )
    @f_DATA.puts '"' + File.basename(@file) + "\"\t\"<empty>\""
    
  elsif ( ! na and content )
    @data_contents.each do |line|
      file_exists = File.exist?( @data_dir + '/' + line ) if ( line =~ /\w+/ )
      if ( file_exists )
        @f_DATA.puts '"' + File.basename(@file) + "\"\t\"#{line}\""
      else
        error("Missing data file \"#{line}\" in the data file directory. Ensure the file exists " +
          "in the \"#{@data_dir}\" directory specified in the SBTM.YML configuration file.")
      end
    end
  end
end

##
# Examine the contents of the TEST NOTES section of the session sheet.
#
# Output:
# * the contents of this section are immediately saved to file
#
def parse_testnotes
  na = false
  content = false
  
  @testnotes_contents.each do |line|
    if ( line =~ /^#N\/A/i )
      na = true
    elsif ( line =~ /\w+/ )
      content = true
    end
  end
  
  if ( ! na and ! content)
    error('TEST NOTES section is empty. If you have no notes, specify #N/A.')
    
  elsif ( na and content )
    error('Unexpected text found with #N/A tag in TEST NOTES section. ' +
      'If you specify #N/A, no other text is permitted in this section.')
    
  elsif ( na and ! content )
    @f_TESTNOTES.puts '"' + File.basename(@file) + "\"\t\"<empty>\""
    warning('There are *no* Test Notes in this sheet. Are there no thoughts, ' +
      'test ideas, observations or setup information worth noting?')
    
  elsif ( ! na and content )
    clear_final_blanks( @testnotes_contents )
    @f_TESTNOTES.print '"' + File.basename(@file) + "\"\t\""
    @testnotes_contents.each {|x| @f_TESTNOTES.print x }
    @f_TESTNOTES.print "\"\n"
  end
end

##
# Examine the contents of the BUGS section of the session sheet.
#
# Output:
# * the contents of this section are immediately saved to file
# * return a count of all the bugs found in this section
#
def parse_bugs
  na = false
  bug_content = false
  in_bug = false
  bug_id = ''
  single_bug = []
  bug_found = false
  bug_count = 0
  
  @bugs_contents.delete_if {|x| x.strip.empty? }
  
  @bugs_contents.each do |line|
    if ( line =~ /^#N\/A/i )
      na = true
    elsif ( line =~ /\S+/ )
      bug_content = true
    end
    if ( line =~ /^BUG/i or line =~ /^# BUG/i )
      error("Possible typo in BUGS section. Don't put \"BUG\" at the start of a line and don't put \"# BUG\" (space between # and BUG).")
    end
  end
  
  if ( ! na and ! bug_content )
    error('BUGS section is empty. If you have no bugs to report in this session, specify #N/A.')
    
  elsif ( na and bug_content )
    error('Unexpected text found with #N/A tag in BUGS section. If you specify #N/A, no other text is permitted in this section.')
    
  elsif ( na and ! bug_content )
    @f_BUGS.puts '"' + File.basename(@file) + "\"\t\"<empty>\""
    
  elsif ( ! na and bug_content )
    
    @bugs_contents.each do |line|
      if ( line =~ /^#BUG/i )
        if ( in_bug )
          clear_final_blanks( single_bug )
          
          if ( single_bug.empty? )
            error('Empty bug field in BUGS section. Please provide bug description text after each #BUG.')
          else
            @f_BUGS.print '"' + File.basename(@file) + "\"\t\""
            single_bug.each {|x| @f_BUGS.print x }
            @f_BUGS.print "\"\t\"#{bug_id}\"\n"
            bug_count += 1
          end
        end
        
        line =~ /^#BUG\s+(.+)/i ? bug_id = $1 : bug_id = ''
        
        single_bug = []
        in_bug = true
        
      elsif ( in_bug )
        single_bug << line
        bug_found = true if ( line =~ /\S+/ )
        
      elsif ( line =~ /\S+/ )
        error("Unexpected text in BUGS section: \"#{line}\". Please specify #BUG before each bug description in this section.")
      end
    end
    
    if ( in_bug )
      clear_final_blanks( single_bug )
      
      if ( single_bug.empty? )
        error('Empty bug field in BUGS section. Please provide bug description text after each #BUG.')
      else
        @f_BUGS.print '"' + File.basename(@file) + "\"\t\""
        single_bug.each {|x| @f_BUGS.print x }
        @f_BUGS.print "\"\t\"#{bug_id}\"\n"
        bug_count += 1
      end
    end
  end
  
  return bug_count
end

##
# Examine the contents of the ISSUES section of the session sheet.
#
# Output:
# * the contents of this section are immediately saved to file
# * return a count of all the issues found in this section
#
def parse_issues
  na = false
  issue_content = false
  in_issue = false
  issue_id = ''
  single_issue = []
  issue_found = false
  issue_count = 0
  
  @issues_contents.delete_if {|x| x.strip.empty? }
  
  @issues_contents.each do |line|
    if ( line =~ /^#N\/A/i )
      na = true
    elsif ( line =~ /\S+/ )
      issue_content = true
    end
    if ( line =~ /^ISSUE/i or line =~ /^# ISSUE/i )
      error("Possible typo in ISSUES section. Don't put \"ISSUE\" at the start of a line and don't put \"# ISSUE\" (space between # and ISSUE).")
    end
  end
  
  if ( ! na and ! issue_content )
    error('ISSUES section is empty. If you have no issues to report in this session, specify #N/A.')
    
  elsif ( na and issue_content )
    error('Unexpected text found with #N/A tag in the ISSUES section. If you specify #N/A, no other text is permitted in this section.')
    
  elsif ( na and ! issue_content )
    @f_ISSUES.puts '"' + File.basename(@file) + "\"\t\"<empty>\""
    
  elsif ( ! na and issue_content )
    
    @issues_contents.each do |line|
      if ( line =~ /^#ISSUE/i )
        if ( in_issue )
          clear_final_blanks( single_issue )
          
          if ( single_issue.empty? )
            error('Empty issue field in ISSUES section. Please include an issue description after each #ISSUE.')
          else
            @f_ISSUES.print '"' + File.basename(@file) + "\"\t\""
            single_issue.each {|x| @f_ISSUES.print x }
            @f_ISSUES.print "\"\t\"#{issue_id}\"\n"
            issue_count += 1
          end
        end
        
        line =~ /^#ISSUE\s+(.+)/i ? issue_id = $1 : issue_id = ''
        
        single_issue = []
        in_issue = true
        
      elsif ( in_issue )
        single_issue << line
        issue_found = true if ( line =~ /\S+/ )
        
      elsif ( line =~ /\S+/ )
        error("Unexpected text in ISSUES section: \"#{line}\". Please specify #ISSUE before each issue in this section.")
      end
    end
    
    if ( in_issue )
      clear_final_blanks( single_issue )
      
      if ( single_issue.empty? )
        error('Empty issue field in ISSUES section. Please include an issue description after each #ISSUE.')
      else
        @f_ISSUES.print '"' + File.basename(@file) + "\"\t\""
        single_issue.each {|x| @f_ISSUES.print x }
        @f_ISSUES.print "\"\t\"#{issue_id}\"\n"
        issue_count += 1
      end
    end
  end
  
  return issue_count
end

### START ###

# Begin scan :
@errors_found = false

# Get the file lists :
@sheets = Dir[ scan_dir + '/*.ses' ]
@sheets.map! {|x| x.downcase }

todo = []
@sheets.each {|x| todo << x  if ( x =~ /et-todo/ ) }

# (exclude the "et-TODO-*.ses" files)
@sheets.delete_if {|x| x =~ /et-todo/ } unless todo.empty?

# Stop now if there's nothing to scan:
if @sheets.empty? and todo.empty?
  output( 'Nothing to scan.' )
  exit
end

# Read in config files - if required:
if @include_switch['Areas']
  f_CFG = File.open( config_dir + '/coverage.ini' ) rescue die( "Can't open #{config_dir}\\coverage.ini", __LINE__ )
  @areas_list = []
  f_CFG.each do |line|
    @areas_list << line.strip.upcase unless ( line.strip.empty? or line =~ /^#/ )
  end
  f_CFG.close
end

if @include_switch['LTTD']
  f_LTTD_INI = File.open( config_dir + '/LTTD_Areas.ini' ) rescue die( "Can't open #{config_dir}\\LTTD_Areas.ini", __LINE__ )
  @LTTD_Areas = []
  f_LTTD_INI.each do |line|
    @LTTD_Areas << line.strip.upcase unless ( line.strip.empty? or line =~ /^#/ )
  end
  f_LTTD_INI.close
end

# Open files we will use to capture session data:

@f_CHARTERS = File.new( metrics_dir + '/charters.txt', 'w' )
@f_CHARTERS.puts "\"Session\"\t\"Field\"\t\"Value\""

if @include_switch['Build']
  @f_BUILD = File.new( metrics_dir + '/builds.txt', 'w' )
  @f_BUILD.puts "\"Session\"\t\"Build ID\""
end

@f_TESTERS = File.new( metrics_dir + '/testers.txt', 'w' )
@f_TESTERS.puts "\"Session\"\t\"Tester\""

if @include_switch['Data Files']
  @f_DATA = File.new( metrics_dir + '/data.txt', 'w' )
  @f_DATA.puts "\"Session\"\t\"Files\""
end

@f_TESTNOTES = File.new( metrics_dir + '/testnotes.txt', 'w' )
@f_TESTNOTES.puts "\"Session\"\t\"Notes\""

@f_BUGS = File.new( metrics_dir + '/bugs.txt', 'w' )
@f_BUGS.puts "\"Session\"\t\"Bugs\"\t\"ID\""

@f_ISSUES = File.new( metrics_dir + '/issues.txt', 'w' )
@f_ISSUES.puts "\"Session\"\t\"Issues\"\t\"ID\""

# Create a hash of arrays to collect the session sheet data used in the report generation
@sessions = Hash.new { |h,k| h[k] = [] }

if @include_switch['Duration']
  # create a hash of arrays to collect the data for the Date-Time Collision Validation (DTCV)
  dtcv_data = Hash.new { |h,k| h[k] = [] }
end

# Parse the Session sheets:

@sheets.sort.each do |file_path|
  file_name = File.basename( file_path )
  if ( file_name !~ /^et-\w{2,3}-\d{6}-\w\.ses/ )
    # if the filename isn't correct, skip the sheet and go to the next one
    error("Unexpected session file name. If it's a session sheet, its name must be: \"ET-<tester initials>-" +
      "<yymmdd>-<A, B, C, etc.>.SES\". If it's a TODO sheet, its name must be: \"ET-TODO-<priority number>-<title>.SES\"")
  else
    
    @file = file_path
    # DTCV variables :
    testers = []
    datetime = 0
    duration = 0
    breakdown_values = []
    num_bugs = 0
    num_issues = 0
    
    # Parse the file into different sections (arrays), examine each in turn for errors and collect the data :
    section_found = Hash.new
    section_found = parse_file
    
    # (skip to the next file in the odd case that the sheet has no content)
    next unless section_found.has_value? true
    
    # Examine each section found in the session sheet:
    parse_charter if section_found['charter']
    
    datetime = parse_start if section_found['start']
    
    testers = parse_tester if section_found['tester']
    tester_count = testers.size
    
    if @include_switch['Task'] and section_found['breakdown']
      breakdown_values = parse_breakdown( tester_count )
    else
      breakdown_values = ( ['0'] * 6 ) + ( [0] * 6 )
    end
    
    parse_data if @include_switch['Data Files'] and section_found['data']
    parse_testnotes if section_found['notes']
    
    num_bugs = parse_bugs if section_found['bugs']
    num_issues = parse_issues if section_found['issues']
    
    # Collect the session metrics, but not if the Date/Time stamp is missing:
    unless datetime == 0
      @sessions[ file_name ] << datetime
      @sessions[ file_name ] << breakdown_values
      @sessions[ file_name ] << num_bugs
      @sessions[ file_name ] << num_issues
      @sessions[ file_name ] << tester_count
      
      @sessions[ file_name ].flatten!
    end
    
    if @include_switch['Duration']
      # collect the DTCV data :
      duration = breakdown_values.first.to_f * @timebox['normal']
      unless testers.empty? or ( datetime == 0 ) or duration.zero?
        testers.each { |name| dtcv_data[ name.downcase ] << [ file_name.upcase, datetime, duration.to_i ] }
      end
    end
  
  end
end

@f_CHARTERS.close
@f_BUILD.close if @include_switch['Build']
@f_TESTERS.close
@f_DATA.close if @include_switch['Data Files']
@f_TESTNOTES.close
@f_BUGS.close
@f_ISSUES.close


## Parse the ToDo files, if present in the same folder :

unless todo.empty?

  @f_CHARTERS = File.new( metrics_dir + '/charters-todo.txt', 'w+')
  @f_CHARTERS.puts "\"Session\"\t\"Field\"\t\"Value\""

  todo.each do |file_path|
    @file = file_path
    section_found = Hash.new
    section_found = parse_file
    parse_charter( 'todo' ) if section_found['charter']
    parse_start( 'todo' ) if section_found['start']
  end

  ## Read in the charters-todo.txt file so we can rewrite it into a different layout:

  @f_CHARTERS.rewind
  @f_CHARTERS.gets    # (ignore heading line)

  todo_raw = []
  @f_CHARTERS.each_line {|line| todo_raw << line}
  @f_CHARTERS.close

  todo_data = []

  # (compress multi-line Charter descriptions into single lines)
  temp = ''
  todo_raw.each do |line|
    temp << line.chomp
    if temp[-1,1] == '"'
      todo_data << temp
      temp = ''
    else
      temp << ' '
    end
  end

  unless ( todo_data.empty? )
    # (compress multi-line Areas into single lines. Rewrite the 'charters-todo' file.)
    prev_session = ''
    session = ''
    field = ''
    content = ''
    todolist = Hash.new { |h,k| h[k] = [] }
    areas = []
    
    ##
    # A DRY method for parsing TODO files <em>(i.e. repeated code that was extracted out into a method for maintainability)</em>
    # * return an "empty or missing" message if there are no Areas. This allows the output file to print correctly.
    # * return the specified Areas -- joined by ';' if there are more than one.
    #
    def area_content( area_data )
      if area_data.empty?
        return '<empty or missing>'
      else
        return area_data.join(';')
      end
    end
    
    todo_data.each do |line|
      (x, session, x, field, x, content) = line.split('"')
      
      if ( field == 'DESCRIPTION' )
        todolist[session] << content
        if ( session != prev_session ) and ( ! prev_session.empty? )
          todolist[prev_session] << area_content( areas )
          areas = []
        end
      else
        todolist[session] << '<empty or missing>' if todolist[session].empty?
        if ( session != prev_session ) and ( ! prev_session.empty? )
          todolist[prev_session] << area_content( areas )
          areas = []
        end
        areas << content
      end
      prev_session = session
    end
    
    todolist[session] << '<empty or missing>' if todolist[session].empty?
    todolist[session] << area_content( areas )
    
    # For the record, I have no idea why we are overwriting the same file here.
    # This new 'charters-todo.txt' file is practically identical to the 'todo.txt' file in the 'todo' folder.
    f_CHARTERS = File.new( metrics_dir + '/charters-todo.txt', 'w')
    f_CHARTERS.puts "\"Title\"\t\"Area\"\t\"Priority\"\t\"Description\""
    
    title = ''
    priority = ''
    todolist.sort.each do |session, value|
      session =~ /et-todo-(\d)-(.+)\.ses/
      priority = $1
      title = $2
      
      f_CHARTERS.puts '"' + title + "\"\t\"" + value.last + 
        "\"\t\"" + priority + "\"\t\"" + value.first + '"'
    end
    f_CHARTERS.close
  end

end

if @include_switch['Duration']

  # Perform the Date-Time Collision Validation (DTCV) :
  dtcv_data.each_key do |tester|
    # For each tester in the data set, check to make sure that consecutive test sessions 
    # do NOT overlap by a significant amount of time. 
    # This value is specified in the SBTM.YML config file: @timebox['allowable_session_overlap']
    
    tester_data = []
    tester_data = dtcv_data[ tester ].sort { |x,y| (x[0] <=> y[0]) }
    
    data_points = tester_data.size
    
    if data_points > 1
      data_points.times do |x|
        if x + 1 < data_points
          
          session_A = tester_data[ x ]
          session_B = tester_data[ x + 1 ]
          
          first_start_time = session_A[1]
          first_end_time = first_start_time + ( session_A[2] * 60 )
          second_start_time = session_B[1]
          
          if ( first_start_time == second_start_time )
            # Check for copy-and-paste errors - identical timestamps
            @errors_found = true
            output( "\n*** Error : START timestamps for two sessions are identical: \"#{ session_A[ 0 ] }\" and \"#{ session_B[ 0 ] }\"" )
          
          elsif ( second_start_time < ( first_end_time - (@timebox['allowable_session_overlap'] * 60) ) )
            # Check for session collisions - i.e. ones that start before the last one has ended (allowing for a configurable amount of overlap - e.g. 5 mins)
            @errors_found = true
            output( "\n*** Error : START timestamp in \"#{ session_B[ 0 ] }\" begins *before* the previous session \"#{ session_A[ 0 ] }\" has ended!" )
          end
          
        end
      end
    end
  end

end


# -----

## Calculate Session Metrics and Totals, Print them to the Output files :

if @include_switch['Areas']
  testarea = Hash.new { |h,k| h[k] = [] }
  
  f_CHARTERS = File.open( metrics_dir + '/charters.txt' )
  f_CHARTERS.gets     # (ignore heading line)
  f_CHARTERS.each_line { |line| testarea[ line.split('"')[5] ] << line.split('"')[1]  if ( line.split('"')[3] == 'AREA' ) }     # ( testarea[ area ] << [session] )
  f_CHARTERS.close
end

testers = Hash.new { |h,k| h[k] = [] }

f_TESTERS = File.open( metrics_dir + '/testers.txt' )
f_TESTERS.gets     # (ignore heading line)
f_TESTERS.each_line { |line| testers[ line.split('"')[3] ] << line.split('"')[1] }     # ( testers[ tester_name ] << [session] )
f_TESTERS.close

f_DAYBREAKS = File.new( metrics_dir + '/breakdowns-day.txt', 'w' )
f_DAYBREAKS.puts "\"Date\"\t\"Total\"\t\"On Charter\"\t\"Opportunity\"\t\"Test\"\t\"Bug\"\t\"Setup\"\t\"Bugs\"\t\"Issues\""

n_total = {}
n_charter = {}
n_opportunity = {}
n_test = {}
n_bug = {}
n_prep = {}
bugs = {}
issues = {}

@sessions.each do |key, value|
  date = Date.parse( value[0].to_s )    # (this creates a 'date' object)
  n_total.has_key?( date ) ?        n_total[ date ] += value[7] :         n_total[ date ] = value[7]
  n_charter.has_key?( date ) ?      n_charter[ date ] += value[8] :       n_charter[ date ] = value[8]
  n_opportunity.has_key?( date ) ?  n_opportunity[ date ] += value[9] :   n_opportunity[ date ] = value[9]
  n_test.has_key?( date ) ?         n_test[ date ] += value[10] :         n_test[ date ] = value[10]
  n_bug.has_key?( date ) ?          n_bug[ date ] += value[11] :          n_bug[ date ] = value[11]
  n_prep.has_key?( date ) ?         n_prep[ date ] += value[12] :         n_prep[ date ] = value[12]
  bugs.has_key?( date ) ?           bugs[ date ] += value[13] :           bugs[ date ] = value[13]
  issues.has_key?( date ) ?         issues[ date ] += value[14] :         issues[ date ] = value[14]
end

n_total.sort { |a,b| b[0] <=> a[0] }.each do | date, value |     # (descending Date sort)
  f_DAYBREAKS.puts '"' + date.strftime("%Y-%m-%d") + "\"\t\"" + 
    n_total[ date ].to_s + "\"\t\"" + 
    n_charter[ date ].to_s + "\"\t\"" + 
    n_opportunity[ date ].to_s + "\"\t\"" + 
    n_test[ date ].to_s + "\"\t\"" + 
    n_bug[ date ].to_s + "\"\t\"" + 
    n_prep[ date ].to_s + "\"\t\"" + 
    bugs[ date ].to_s + "\"\t\"" + 
    issues[ date ].to_s + '"'
end

f_DAYBREAKS.close

f_TDAYBREAKS = File.new( metrics_dir + '/breakdowns-tester-day.txt', 'w' )
f_TDAYBREAKS.puts "\"Tester\"\t\"Date\"\t\"Total\"\t\"On Charter\"\t\"Opportunity\"\t\"Test\"\t\"Bug\"\t\"Setup\"\t\"Bugs\"\t\"Issues\""

f_TESTERTOTALS = File.new( metrics_dir + '/breakdowns-testers-total.txt', 'w' )
f_TESTERTOTALS.puts "\"Tester\"\t\"Total\"\t\"On Charter\"\t\"Opportunity\"\t\"Test\"\t\"Bug\"\t\"Setup\"\t\"Bugs\"\t\"Issues\""

f_TESTERBREAKS = File.new( metrics_dir + '/breakdowns-testers-sessions.txt', 'w' )
f_TESTERBREAKS.puts "\"Session\"\t" + 
  "\"Start\"\t" + 
  "\"Time\"\t" + 
  "\"Duration\"\t" + 
  "\"On Charter\"\t" + 
  "\"On Opportunity\"\t" + 
  "\"Test\"\t" + 
  "\"Bug\"\t" + 
  "\"Setup\"\t" + 
  "\"N Total\"\t" + 
  "\"N On Charter\"\t" + 
  "\"N Opportunity\"\t" + 
  "\"N Test\"\t" + 
  "\"N Bug\"\t" + 
  "\"N Setup\"\t" + 
  "\"Bugs\"\t" + 
  "\"Issues\"\t" + 
  "\"Testers\"\t" + 
  '"Tester"'


testers.sort.each do | tester_name, session_list |
  tn_total = {} ;        dn_total = {}
  tn_charter = {} ;      dn_charter = {}
  tn_opportunity = {} ;  dn_opportunity = {}
  tn_prep = {} ;         dn_prep = {}
  tn_test = {} ;         dn_test = {}
  tn_bug = {} ;          dn_bug = {}
  tn_tester = {} ;       dn_tester = {}
  tbugs = {} ;           dbugs = {}
  tissues = {} ;         dissues = {}
  
  session_list.each do | sess_name |
    if @sessions.has_key? sess_name
      start         = Date.parse( @sessions[ sess_name ][0].to_s )
      time          = @sessions[ sess_name ][0]
      duration      = @sessions[ sess_name ][1]
      oncharter     = @sessions[ sess_name ][2]
      onopportunity = @sessions[ sess_name ][3]
      test          = @sessions[ sess_name ][4]
      bug           = @sessions[ sess_name ][5]
      prep          = @sessions[ sess_name ][6]
      n_total       = @sessions[ sess_name ][7]
      n_charter     = @sessions[ sess_name ][8]
      n_opportunity = @sessions[ sess_name ][9]
      n_test        = @sessions[ sess_name ][10]
      n_bug         = @sessions[ sess_name ][11]
      n_prep        = @sessions[ sess_name ][12]
      bugs          = @sessions[ sess_name ][13].to_f     # (to help more accurately split counts between multiple testers)
      issues        = @sessions[ sess_name ][14].to_f
      testers       = @sessions[ sess_name ][15]
      
      f_TESTERBREAKS.puts '"' + sess_name + "\"\t\"" + 
        start.strftime("%Y-%m-%d") + "\"\t\"" + 
        time.strftime("%I:%M %p").downcase + "\"\t\"" + 
        duration + "\"\t\"" + 
        oncharter + "\"\t\"" + 
        onopportunity + "\"\t\"" + 
        test + "\"\t\"" + 
        bug + "\"\t\"" + 
        prep + "\"\t\"" + 
        ( n_total/testers ).to_s + "\"\t\"" + 
        ( n_charter/testers ).to_s + "\"\t\"" + 
        ( n_opportunity/testers ).to_s + "\"\t\"" + 
        ( n_test/testers ).to_s + "\"\t\"" + 
        ( n_bug/testers ).to_s + "\"\t\"" + 
        ( n_prep/testers ).to_s + "\"\t\"" + 
        ( bugs/testers ).to_s + "\"\t\"" + 
        ( issues/testers ).to_s + "\"\t\"" + 
        testers.to_s + "\"\t\"" + 
        tester_name + '"'
      
      tn_total.has_key?( tester_name ) ?       tn_total[ tester_name ] += ( n_total/testers ) :             tn_total[ tester_name ] = ( n_total/testers )
      tn_charter.has_key?( tester_name ) ?     tn_charter[ tester_name ] += ( n_charter/testers ) :         tn_charter[ tester_name ] = ( n_charter/testers )
      tn_opportunity.has_key?( tester_name ) ? tn_opportunity[ tester_name ] += ( n_opportunity/testers ) : tn_opportunity[ tester_name ] = ( n_opportunity/testers )
      tn_test.has_key?( tester_name ) ?        tn_test[ tester_name ] += ( n_test/testers ) :               tn_test[ tester_name ] = ( n_test/testers )
      tn_bug.has_key?( tester_name ) ?         tn_bug[ tester_name ] += ( n_bug/testers ) :                 tn_bug[ tester_name ] = ( n_bug/testers )
      tn_prep.has_key?( tester_name ) ?        tn_prep[ tester_name ] += ( n_prep/testers ) :               tn_prep[ tester_name ] = ( n_prep/testers )
      tbugs.has_key?( tester_name ) ?          tbugs[ tester_name ] += ( bugs/testers ) :                   tbugs[ tester_name ] = ( bugs/testers )
      tissues.has_key?( tester_name ) ?        tissues[ tester_name ] += ( issues/testers ) :               tissues[ tester_name ] = ( issues/testers )
      
      # these next lines are for f_TDAYBREAKS only
      dnew_key = start.to_s + "\t" + tester_name
      dn_total.has_key?( dnew_key ) ?        dn_total[ dnew_key ] += ( n_total/testers ) :             dn_total[ dnew_key ] = ( n_total/testers )
      dn_charter.has_key?( dnew_key ) ?      dn_charter[ dnew_key ] += ( n_charter/testers ) :         dn_charter[ dnew_key ] = ( n_charter/testers )
      dn_opportunity.has_key?( dnew_key ) ?  dn_opportunity[ dnew_key ] += ( n_opportunity/testers ) : dn_opportunity[ dnew_key ] = ( n_opportunity/testers )
      dn_test.has_key?( dnew_key ) ?         dn_test[ dnew_key ] += ( n_test/testers ) :               dn_test[ dnew_key ] = ( n_test/testers )
      dn_bug.has_key?( dnew_key ) ?          dn_bug[ dnew_key ] += ( n_bug/testers ) :                 dn_bug[ dnew_key ] = ( n_bug/testers )
      dn_prep.has_key?( dnew_key ) ?         dn_prep[ dnew_key ] += ( n_prep/testers ) :               dn_prep[ dnew_key ] = ( n_prep/testers )
      dbugs.has_key?( dnew_key ) ?           dbugs[ dnew_key ] += ( bugs/testers ) :                   dbugs[ dnew_key ] = ( bugs/testers )
      dissues.has_key?( dnew_key ) ?         dissues[ dnew_key ] += ( issues/testers ) :               dissues[ dnew_key ] = ( issues/testers )
      
    end
  end
  
  f_TESTERTOTALS.puts '"' + tester_name + "\"\t\"" + 
    tn_total[ tester_name ].to_s + "\"\t\"" + 
    tn_charter[ tester_name ].to_s + "\"\t\"" + 
    tn_opportunity[ tester_name ].to_s + "\"\t\"" + 
    tn_test[ tester_name ].to_s + "\"\t\"" + 
    tn_bug[ tester_name ].to_s + "\"\t\"" + 
    tn_prep[ tester_name ].to_s + "\"\t\"" + 
    tbugs[ tester_name ].to_s + "\"\t\"" + 
    tissues[ tester_name ].to_s + '"'
  
  dn_total.sort.each do | date_name, value |
    start = Date.parse( date_name.split(/\t/)[0] )
    f_TDAYBREAKS.puts '"' + tester_name + "\"\t\"" + 
      start.strftime("%Y-%m-%d") + "\"\t\"" + 
      dn_total[ date_name ].to_s + "\"\t\"" + 
      dn_charter[ date_name ].to_s + "\"\t\"" + 
      dn_opportunity[ date_name ].to_s + "\"\t\"" + 
      dn_test[ date_name ].to_s + "\"\t\"" + 
      dn_bug[ date_name ].to_s + "\"\t\"" + 
      dn_prep[ date_name ].to_s + "\"\t\"" + 
      dbugs[ date_name ].to_s + "\"\t\"" + 
      dissues[ date_name ].to_s + '"'
  end
end

f_TDAYBREAKS.close
f_TESTERTOTALS.close
f_TESTERBREAKS.close

if @include_switch['Areas']

  f_COVERAGEBREAKS = File.new( metrics_dir + '/breakdowns-coverage-sessions.txt', 'w' )
  f_COVERAGEBREAKS.puts "\"Session\"\t" + 
    "\"Start\"\t" + 
    "\"Time\"\t" + 
    "\"Duration\"\t" + 
    "\"On Charter\"\t" + 
    "\"On Opportunity\"\t" + 
    "\"Test\"\t" + 
    "\"Bug\"\t" + 
    "\"Setup\"\t" + 
    "\"N Total\"\t" + 
    "\"N On Charter\"\t" + 
    "\"N Opportunity\"\t" + 
    "\"N Test\"\t" + 
    "\"N Bug\"\t" + 
    "\"N Setup\"\t" + 
    "\"Bugs\"\t" + 
    "\"Issues\"\t" + 
    "\"Testers\"\t" + 
    '"Area"'
  
  f_COVERAGETOTALS = File.new( metrics_dir + '/breakdowns-coverage-total.txt', 'w' )
  f_COVERAGETOTALS.puts "\"Total\"\t\"On Charter\"\t\"Opportunity\"\t\"Test\"\t\"Bug\"\t\"Setup\"\t\"Bugs\"\t\"Issues\"\t\"Area\""

  @areas_list.sort.each do |area|
    tn_total = {}
    tn_charter = {}
    tn_opportunity = {}
    tn_prep = {}
    tn_test = {}
    tn_bug = {}
    tn_tester = {}
    tbugs = {}
    tissues = {}
    
    if testarea.has_key?( area )
      session_list = testarea[ area ]
    else
      # (fill in blanks for the Coverage.ini Areas not yet covered)
      f_COVERAGEBREAKS.puts "\"\"\t" * 18 + '"' + area + '"'
      session_list = []
    end
    
    session_list.each do | sess_name |
      if @sessions.has_key? sess_name
        start         = Date.parse( @sessions[ sess_name ][0].to_s )
        time          = @sessions[ sess_name ][0]
        duration      = @sessions[ sess_name ][1]
        oncharter     = @sessions[ sess_name ][2]
        onopportunity = @sessions[ sess_name ][3]
        test          = @sessions[ sess_name ][4]
        bug           = @sessions[ sess_name ][5]
        prep          = @sessions[ sess_name ][6]
        n_total       = @sessions[ sess_name ][7]
        n_charter     = @sessions[ sess_name ][8]
        n_opportunity = @sessions[ sess_name ][9]
        n_test        = @sessions[ sess_name ][10]
        n_bug         = @sessions[ sess_name ][11]
        n_prep        = @sessions[ sess_name ][12]
        bugs          = @sessions[ sess_name ][13]
        issues        = @sessions[ sess_name ][14]
        testers       = @sessions[ sess_name ][15]
        
        f_COVERAGEBREAKS.puts '"' + sess_name + "\"\t\"" + 
          start.strftime("%Y-%m-%d") + "\"\t\"" + 
          time.strftime("%I:%M %p").downcase + "\"\t\"" + 
          duration + "\"\t\"" + 
          oncharter + "\"\t\"" + 
          onopportunity + "\"\t\"" + 
          test + "\"\t\"" + 
          bug + "\"\t\"" + 
          prep + "\"\t\"" + 
          n_total.to_s + "\"\t\"" + 
          n_charter.to_s + "\"\t\"" + 
          n_opportunity.to_s + "\"\t\"" + 
          n_test.to_s + "\"\t\"" + 
          n_bug.to_s + "\"\t\"" + 
          n_prep.to_s + "\"\t\"" + 
          bugs.to_s + "\"\t\"" + 
          issues.to_s + "\"\t\"" + 
          testers.to_s + "\"\t\"" + 
          area + '"'
        
        tn_total.has_key?( area ) ?        tn_total[ area ] += n_total :             tn_total[ area ] = n_total
        tn_charter.has_key?( area ) ?      tn_charter[ area ] += n_charter :         tn_charter[ area ] = n_charter
        tn_opportunity.has_key?( area ) ?  tn_opportunity[ area ] += n_opportunity : tn_opportunity[ area ] = n_opportunity
        tn_test.has_key?( area ) ?         tn_test[ area ] += n_test :               tn_test[ area ] = n_test
        tn_bug.has_key?( area ) ?          tn_bug[ area ] += n_bug :                 tn_bug[ area ] = n_bug
        tn_prep.has_key?( area ) ?         tn_prep[ area ] += n_prep :               tn_prep[ area ] = n_prep
        tbugs.has_key?( area ) ?           tbugs[ area ] += bugs :                   tbugs[ area ] = bugs
        tissues.has_key?( area ) ?         tissues[ area ] += issues :               tissues[ area ] = issues
        
      end
    end
    
    if testarea.has_key?( area )
      f_COVERAGETOTALS.puts '"' + tn_total[ area ].to_s + "\"\t\"" + 
        tn_charter[ area ].to_s + "\"\t\"" + 
        tn_opportunity[ area ].to_s + "\"\t\"" + 
        tn_test[ area ].to_s + "\"\t\"" + 
        tn_bug[ area ].to_s + "\"\t\"" + 
        tn_prep[ area ].to_s + "\"\t\"" + 
        tbugs[ area ].to_s + "\"\t\"" + 
        tissues[ area ].to_s + "\"\t\"" + 
        area + '"'
    else
      f_COVERAGETOTALS.puts "\"0\"\t" * 8 + '"' + area + '"'
    end
  end

  f_COVERAGETOTALS.close
  f_COVERAGEBREAKS.close
end


## Re-Sort the Sessions (descending by Date+Time) and output to the Breakdowns file :
resorted_array = []
@sessions.each { |file_name, data| resorted_array << data.unshift( file_name ) }
resorted_array.sort! { |a,b| b[1] <=> a[1] }

f_BREAKDOWNS = File.new( metrics_dir + '/breakdowns.txt', 'w' )
f_BREAKDOWNS.puts "\"Session\"\t" +
    "\"Start\"\t" +
    "\"Time\"\t" +
    "\"Duration\"\t" +
    "\"On Charter\"\t" +
    "\"On Opportunity\"\t" +
    "\"Test\"\t" +
    "\"Bug\"\t" +
    "\"Setup\"\t" +
    "\"N Total\"\t" +
    "\"N On Charter\"\t" +
    "\"N Opportunity\"\t" +
    "\"N Test\"\t" +
    "\"N Bug\"\t" +
    "\"N Setup\"\t" +
    "\"Bugs\"\t" +
    "\"Issues\"\t" +
    "\"Testers\""

resorted_array.each do |data|
  f_BREAKDOWNS.print '"'
  data.each_index do |x|
    if x == 1    # (i.e. the Time object)
      f_BREAKDOWNS.print data[x].strftime("%Y-%m-%d") + "\"\t\""
      f_BREAKDOWNS.print data[x].strftime("%I:%M %p").downcase + "\"\t\""
    else
      if x == (data.size - 1)
        f_BREAKDOWNS.print data[x].to_s
        f_BREAKDOWNS.puts '"'
      else
        f_BREAKDOWNS.print data[x].to_s + "\"\t\""
      end
    end
  end
end

f_BREAKDOWNS.close


## Final Note :
if @errors_found
  msg = "\nErrors Found!  Please correct the session sheet(s) listed above and re-run the scan utility."
else
  msg = 'Your papers are in order!'
end

output( msg )

### END ###