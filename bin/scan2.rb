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
# Last Updated:: 30 May 2011
# Version:: 2.0
# -----
@ScriptName = File.basename($0).upcase

if ( ARGV.length < 2 ) or ! File.exist?( ARGV[0] + '/sbtm.yml' )
  puts "\n!! Invalid or incorrect number of command line arguments specified."
  puts "\nUsage: #{@ScriptName} [CONFIG_DIR] [FOLDER_TO_SCAN]"
  puts "\nWhere:"
  puts "* CONFIG_DIR     = the path to the directory containing SBTM.YML"
  puts "* FOLDER_TO_SCAN = the path to the directory containing the session sheets\n"
  exit
end

# Load some basic Ruby libraries - YAML and Time.
require 'yaml'
require 'Time' unless Time.methods.include? 'parse'

# Read the Configuration file:
config = YAML.load_file( ARGV[0] + '/sbtm.yml' )

begin
  scandir = ARGV[1]
  @filedir = config['folders']['data_dir']
  configdir = config['folders']['config_dir']
  metricsdir = config['folders']['metrics_dir']
  
  logfile = config['output']['logfile']
  
  @timebox = config['timebox']
  
  @include_switch = config['scan_options']
rescue
  puts '*'*50
  puts 'Error reading value from SBTM.YML!'
  puts '*'*50
  exit
end

# CHECK that the file directories specified appear to be valid:
[ scandir, @filedir, metricsdir ].each do |folder|
  unless FileTest.directory?( folder )
    puts '*'*50
    puts "'" + folder + "' is not a valid directory!" 
    puts "Please check the name specified and try again."
    puts '*'*50
    exit
  end
end

# CHECK for the Log file argument and check for valid filename chars if given
logfile = '' if logfile =~ /^\./    # Don't start a filename with a dot!
logfile.gsub!( /[?:*"<>|]/, '')   # Remove some unwanted filename characters just in case they show up.
if logfile.empty?
  puts '!! Invalid filename specified for the LOG FILE.  Outputting to console...'
  @outfile = NIL
else
  @outfile = File.new( logfile, 'w' )
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
  charter_found = false ;    @charter_contents = []
  start_found = false ;      @start_contents = []
  tester_found = false ;     @tester_contents = []
  breakdown_found = false ;  @breakdown_contents = []
  data_found = false ;       @data_contents = []
  testnotes_found = false ;  @testnotes_contents = []
  bugs_found = false ;       @bugs_contents = []
  issues_found = false ;     @issues_contents = []
  tab_char_found = false

  f_SESSION = File.open( @file ) rescue die( "Can't open #{@file}", __LINE__ )
  
  while ( line = f_SESSION.gets )
    # NOTE: These session sheet section headings *must* be in all CAPS.
    if ( line =~ /^CHARTER/)
      error("More than one CHARTER section")  if ( charter_found )
      line = f_SESSION.gets     # automatically skip the next line (should be dashed line)
      charter_found = true
      reference_array = @charter_contents
      next
    elsif ( line =~ /^START/)
      error("More than one START section")  if ( start_found )
      line = f_SESSION.gets
      start_found = true
      reference_array = @start_contents
      next
    elsif ( line =~ /^TESTER/)
      error("More than one TESTER section")  if ( tester_found )
      line = f_SESSION.gets
      tester_found = true
      reference_array = @tester_contents
      next
    elsif ( line =~ /^TASK BREAKDOWN/)
      # Separate out any content found here even if @include_switch['Task'] = false
      # this will make sure that this content doesn't mistakenly get added to the section above in the session sheet.
      
      error("More than one TASK BREAKDOWN section")  if ( breakdown_found )
      line = f_SESSION.gets
      breakdown_found = true
      reference_array = @breakdown_contents
      
      warning("TASK BREAKDOWN section found but skipped due to SCAN switch used.") unless @include_switch['Task']
      next
    elsif ( line =~ /^DATA FILES/)
      # Separate out any content found here even if @include_switch['Data Files'] = false
      # this will make sure that this content doesn't mistakenly get added to the section above in the session sheet.
      
      error("More than one DATA FILES section")  if ( data_found )
      line = f_SESSION.gets
      data_found = true
      reference_array = @data_contents
      
      warning("DATA FILES section found but skipped due to SCAN switch used.") unless @include_switch['Data Files']
      
      next
    elsif ( line =~ /^TEST NOTES/)
      error("More than one TEST NOTES section")  if ( testnotes_found )
      line = f_SESSION.gets
      testnotes_found = true
      reference_array = @testnotes_contents
      next
    elsif ( line =~ /^BUGS/)
      error("More than one BUGS section")  if ( bugs_found )
      line = f_SESSION.gets
      bugs_found = true
      reference_array = @bugs_contents
      next
    elsif ( line =~ /^ISSUES/)
      error("More than one ISSUES section")  if ( issues_found )
      line = f_SESSION.gets
      issues_found = true
      reference_array = @issues_contents
      next
    end
    line.gsub!('"', "'") if line.include? '"'
    reference_array << line rescue true   # (Rescue in case there are blank lines at the start of the file and the reference_array variable isn't set yet)
    tab_char_found = true if ( line =~ /\t/)
  end
  
  error("Missing a CHARTER section") unless charter_found
  error("Missing a START section") unless start_found
  error("Missing a TESTER section") unless tester_found
  error("Missing a TASK BREAKDOWN section") if @include_switch['Task'] and ! breakdown_found
  error("Missing a DATA FILES section") if @include_switch['Data Files'] and ! data_found
  error("Missing a TEST NOTES section") unless testnotes_found
  error("Missing a BUGS section") unless bugs_found
  error("Missing an ISSUES section") unless issues_found
  warning("[Tab] character found in file.  Tabs may cause unexpected formatting in different editors.  Please convert Tabs to Spaces if possible.") if tab_char_found
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
# There are two optional sub-sections that may appear here:
# * ##LTTD_AREA
# * ##AREAS
# The sub-sections may be enabled in the SBTML.YML configuration file.
#
# Output:
# * Charter text is immediately saved to file
#
def parse_charter( session_type = 'test' )
  charter_complete = false ;  charter_desc = []
  lttd_found = false ;        lttd_area = []
  area_found = false ;        areas = []
  in_section = ''
  build_line_found = false
  strategy_line_found = false
  os_line_found = false
  
  @charter_contents.delete_if {|x| x.strip.empty? }

  @charter_contents.each do |line|
    
    if ( line =~ /^#AREAS/ and @include_switch['Areas'] )
      error('More than one #AREAS hashtag found in CHARTER section') if ( area_found )
      area_found = true
      in_section = 'AREA'
    elsif ( line =~ /^#LTTD_AREA/ and @include_switch['LTTD'] )
      error('More than one #LTTD_AREA hashtag found in CHARTER section') if ( lttd_found )
      lttd_found = true
      in_section = 'LTTD'
    end
    if ( ! charter_complete )
      charter_desc << line unless ( line =~ /^#/ ) or ( lttd_found ) or ( area_found )
      
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
      
    elsif ( ! lttd_found ) and ( ! area_found ) and ( line !~ /^#/ )
      error("Unexpected text \"#{line.chomp}\" found in CHARTER section. The charter description ends when '#' starts a new line. All other text in the CHARTER section must be preceded by a valid '#' hashtag.")
      
    end
    
    case in_section
    when 'LTTD'
      next if line =~ /^#/
      line.strip!.upcase!
      if @LTTD_Areas.include?( line )
        lttd_area << line unless lttd_area.include?( line )     # (avoid duplicates)
      else
        error("Unexpected #LTTD_AREA label \"#{line}\" in CHARTER section. Ensure that label exists in LTTD_AREAS.INI.")
      end
    when 'AREA'
      next if line =~ /^#/
      line.strip!.upcase!
      build_line_found = true if ( line =~ /^BUILD/ )     # (Hard-coded this keyword to be the *minimum* requirement for the #AREAS section)
      strategy_line_found = true if ( line =~ /STRATEGY/ )     # (Sessions should always have a Strategy too)
      
      if @areas_list.include?( line )
        areas << line unless areas.include?( line )     # (avoid duplicates)
      else
        error("Unexpected #AREAS label \"#{line}\" in CHARTER section. Ensure that label exists in COVERAGE.INI.")
      end
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
  
  error('Missing charter description in CHARTER section.') unless ( charter_complete )
  error('Missing #LTTD_AREA value in CHARTER section. Ensure the #LTTD_AREA hashtag is present and has valid area values underneath.') if @include_switch['LTTD']  and ( ! lttd_found or  lttd_area.empty? )
  error('Missing #AREAS values in CHARTER section. Ensure the #AREAS hashtag is present and has valid area values underneath.') if @include_switch['Areas'] and ! area_found
  unless session_type == 'todo'
    error("Missing 'BUILD' line in the #AREAS section.  Please add it.") if @include_switch['Areas'] and ! build_line_found
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
  start_date = ''
  start_time = ''
  datetime_value = 0

  File.basename( @file ) =~ /-(\d\d)(\d\d)(\d\d)-/
  fn_year = $1
  fn_month = $2.to_i
  fn_day = $3.to_i
  
  @start_contents.delete_if {|x| x.strip.empty? }
  @start_contents.each do |line|
    line.strip!
    if (line =~ /^(\d+)\/(\d+)\/(\d{2,4})\s+(\d+):(\d+)\s*(am|pm)?$/i)
      time_line = Time.parse( line )
      if ( time_found )
        error('Multiple time stamps detected in START section')
      else
        time_found = true
        
        if ((( time_line.mon != fn_month ) or ( time_line.day != fn_day) or ( time_line.strftime("%y") != fn_year )) and session_type == 'test' )
          error('File name does not match date in START section')
        end
        # (Aside: no longer stripping the leading 0's from the date and time values in the reports - makes for nicer formatting)
        start_date = time_line.strftime("%m/%d/%y")
        start_time = time_line.strftime("%I:%M %p").downcase
        datetime_value = time_line.to_i
      end
    elsif ( ! line.empty? )
      error("Unexpected text found \"#{line}\" in START section. Ensure that the time stamp is in this format: mm/dd/yyyy hh:mm{am|pm}. 12-hr or 24-hr time format works.")
    end
  end
  error('Missing time stamp in START section') if (! time_found && session_type == 'test' )
  error('START section must be empty if the sheet is named as a TODO. Did you forget to rename the session sheet?') if ( time_found && session_type == 'todo' )
  
  return start_date, start_time, datetime_value
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
  dur_found = false ;  dur_happened = false
  tde_found = false ;  tde_happened = false
  bir_found = false ;  bir_happened = false
  set_found = false ;  set_happened = false
  cvo_found = false ;  cvo_happened = false
  
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
        error('More than one #DURATION hashtag found in TASK BREAKDOWN section') if ( dur_found )
        dur_found = true
        in_section = 'DUR'
      else
        warning('#DURATION section found but skipped due to SCAN switch used.')
      end
      next
    when /^#TEST DESIGN AND EXECUTION/
      if @include_switch['TBS']
        error('More than one #TEST DESIGN AND EXECUTION hashtag found in TASK BREAKDOWN section') if ( tde_found )
        tde_found = true
        in_section = 'TDE'
      else
        warning('#TEST DESIGN AND EXECUTION section found but skipped due to SCAN switch used.')
      end
      next
    when /^#BUG INVESTIGATION AND REPORTING/
      if @include_switch['TBS']
        error('More than one #BUG INVESTIGATION AND REPORTING hashtag found in TASK BREAKDOWN section') if ( bir_found )
        bir_found = true
        in_section = 'BIR'
      else
        warning('#BUG INVESTIGATION AND REPORTING section found but skipped due to SCAN switch used.')
      end
      next
    when /^#SESSION SETUP/
      if @include_switch['TBS']
        error('More than one #SESSION SETUP hashtag found in TASK BREAKDOWN section') if ( set_found )
        set_found = true
        in_section = 'SET'
      else
        warning('#SESSION SETUP section found but skipped due to SCAN switch used.')
      end
      next
    when /^#CHARTER VS. OPPORTUNITY/
      if @include_switch['C vs O']
        error('More than one #CHARTER VS. OPPORTUNITY hashtag found in TASK BREAKDOWN section') if ( cvo_found )
        cvo_found = true
        in_section = 'CVO'
      else
        warning('#CHARTER VS. OPPORTUNITY section found but skipped due to SCAN switch used.')
      end
      next
    end
      
    case in_section
    when 'DUR'
      if ( ! dur_happened )
        dur_happened = true
        
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
      if ( ! tde_happened )
        tde_happened = true
        
        test_val = line
        if ( test_val.to_i < 0 or test_val.to_i > 100 ) or ( line =~ /\D+/ )
          error('Unexpected #TEST DESIGN AND EXECUTION value in TASK BREAKDOWN section. Ensure that the value is an integer from 0-100.')
        end
      else
        error("Unexpected value encountered under #TEST DESIGN AND EXECUTION in the TASK BREAKDOWN section: \"#{line}\"" )
      end
      
    when 'BIR'
      if ( ! bir_happened )
        bir_happened = true
        
        bug_val = line
        if ( bug_val.to_i < 0 or bug_val.to_i > 100) or ( line =~ /\D+/ )
          error('Unexpected #BUG INVESTIGATION AND REPORTING value in TASK BREAKDOWN section. Ensure that the value is an integer from 0-100.')
        end
      else
        error("Unexpected value encountered under #BUG INVESTIGATION AND REPORTING in the TASK BREAKDOWN section: \"#{line}\"")
      end
      
    when 'SET'
      if ( ! set_happened )
        set_happened = true
        
        prep_val = line
        if ( prep_val.to_i < 0 or prep_val.to_i > 100) or ( line =~ /\D+/ )
          error('Unexpected #SESSION SETUP value in TASK BREAKDOWN section. Ensure that the value is an integer from 0-100.')
        end
      else
        error("Unexpected value encountered under #SESSION SETUP in the TASK BREAKDOWN section: \"#{line}\"")
      end
      
    when 'CVO'
      if ( ! cvo_happened )
        cvo_happened = true
        
        if ( line !~ /^\d+\s*\/\s*\d+/ )
          error("Unexpected #CHARTER VS. OPPORTUNITY value \"#{line}\" in TASK BREAKDOWN section. Ensure that the values are integers from 0-100 separated by '/'.")
        end
        
        (cha_val, opp_val) = line.split('/')
        
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
  
  error('Missing #DURATION field in TASK BREAKDOWN section') if @include_switch['Duration'] and ( ( ! dur_found ) or ( dur_found and ! dur_happened) )
  error('Missing #TEST DESIGN AND EXECUTION field in TASK BREAKDOWN section') if @include_switch['TBS'] and ( ( ! tde_found ) or ( tde_found and ! tde_happened) )
  error('Missing #BUG INVESTIGATION AND REPORTING field in TASK BREAKDOWN section') if @include_switch['TBS'] and ( ( ! bir_found ) or ( bir_found and ! bir_happened) )
  error('Missing #SESSION SETUP field in TASK BREAKDOWN section') if @include_switch['TBS'] and ( ( ! set_found ) or ( set_found and ! set_happened) )
  error('Missing #CHARTER VS. OPPORTUNITY field in TASK BREAKDOWN section') if @include_switch['C vs O'] and ( ( ! cvo_found ) or ( cvo_found and ! cvo_happened) )
  
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
      file_exists = File.exist?( @filedir + '/' + line ) if ( line =~ /\w+/ )
      if ( file_exists )
        @f_DATA.puts '"' + File.basename(@file) + "\"\t\"#{line}\""
      else
        error("Missing data file \"#{line}\" in the data file directory. Ensure the file exists in the \"#{@filedir}\" directory specified as the second argument on the #{@ScriptName} command line.")
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
    error('Unexpected text found with #N/A tag in TEST NOTES section. If you specify #N/A, no other text is permitted in this section.')
    
  elsif ( na and ! content )
    @f_TESTNOTES.puts '"' + File.basename(@file) + "\"\t\"<empty>\""
    warning('There are *no* Test Notes in this sheet. Are there no thoughts, test ideas, observations or setup information worth noting?')
    
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

# Read in config files - if required:
if @include_switch['Areas']
  f_CFG = File.open( configdir + '/coverage.ini' ) rescue die( "Can't open #{configdir}\\coverage.ini", __LINE__ )
  @areas_list = []
  f_CFG.each do |line|
    @areas_list << line.strip.upcase unless ( line.strip.empty? or line =~ /^#/ )
  end
  f_CFG.close
end

if @include_switch['LTTD']
  f_LTTD_INI = File.open( configdir + '/LTTD_Areas.ini' ) rescue die( "Can't open #{configdir}\\LTTD_Areas.ini", __LINE__ )
  @LTTD_Areas = []
  f_LTTD_INI.each do |line|
    @LTTD_Areas << line.strip.upcase unless ( line.strip.empty? or line =~ /^#/ )
  end
  f_LTTD_INI.close
end

# Get the file lists :
@sheets = Dir[ scandir + '/*.ses' ]
@sheets.map! {|x| x.downcase }

todo = []
@sheets.each {|x| todo << x  if ( x =~ /et-todo/ ) }

# (exclude the "et-TODO-*.ses" files)
@sheets.delete_if {|x| x =~ /et-todo/ } unless todo.empty?

# Open files we will use to capture session data:

@f_CHARTERS = File.new( metricsdir + '/charters.txt', 'w' )
@f_CHARTERS.puts "\"Session\"\t\"Field\"\t\"Value\""

@f_TESTERS = File.new( metricsdir + '/testers.txt', 'w' )
@f_TESTERS.puts "\"Session\"\t\"Tester\""

if @include_switch['Data Files']
  @f_DATA = File.new( metricsdir + '/data.txt', 'w' )
  @f_DATA.puts "\"Session\"\t\"Files\""
end

@f_TESTNOTES = File.new( metricsdir + '/testnotes.txt', 'w' )
@f_TESTNOTES.puts "\"Session\"\t\"Notes\""

@f_BUGS = File.new( metricsdir + '/bugs.txt', 'w' )
@f_BUGS.puts "\"Session\"\t\"Bugs\"\t\"ID\""

@f_ISSUES = File.new( metricsdir + '/issues.txt', 'w' )
@f_ISSUES.puts "\"Session\"\t\"Issues\"\t\"ID\""

# Create a hash of arrays to collect the session sheet data used in the report generation
@sessions = Hash.new { |h,k| h[k] = [] }

if @include_switch['Duration']
  # create a hash of arrays to collect the data for the Date-Time Collision Validation (DTCV)
  dtcv_data = Hash.new { |h,k| h[k] = [] }
end

# Parse the Session sheets:

@sheets.sort.each do |@file|
  file_name = File.basename( @file )
  if ( file_name !~ /^et-\w{2,3}-\d{6}-\w\.ses/ )
    # if the filename isn't correct, skip the sheet and go to the next one
    error("Unexpected session file name. If it's a session sheet, its name must be: \"ET-<tester initials>-<yymmdd>-<A, B, C, etc.>.SES\". If it's a TODO sheet, its name must be: \"ET-TODO-<priority number>-<title>.SES\"")
  else
  
    # DTCV variables :
    testers = []
    datetime = 0
    duration = 0
    start_times = []
    breakdown_values = []
    
    # Parse the file into different sections (arrays), examine each in turn for errors and collect the data :
    parse_file
    testers = parse_tester
    tester_count = testers.size
    
    parse_charter
    
    start_times = parse_start
    datetime = start_times.pop
    @sessions[ file_name ] << start_times
    
    if @include_switch['Task']
      breakdown_values = parse_breakdown( tester_count )
    else
      breakdown_values = ( ['0'] * 6 ) + ( [0] * 6 )
    end
    @sessions[ file_name ] << breakdown_values
    
    parse_data if @include_switch['Data Files']
    parse_testnotes
    @sessions[ file_name ] << parse_bugs
    @sessions[ file_name ] << parse_issues
    @sessions[ file_name ] << tester_count
    
    @sessions[ file_name ].flatten!
    
    if @include_switch['Duration']
      # collect the DTCV data :
      duration = breakdown_values.first.to_f * @timebox['normal']
      unless testers.empty? or datetime.zero? or duration.zero?
        testers.each { |name| dtcv_data[ name.downcase ] << [ file_name.upcase, datetime, duration.to_i ] }
      end
    end
  
  end
end

@f_CHARTERS.close
@f_TESTERS.close
@f_DATA.close if @include_switch['Data Files']
@f_TESTNOTES.close
@f_BUGS.close
@f_ISSUES.close


## Parse the ToDo files, if present in the same folder :

unless todo.empty?

  @f_CHARTERS = File.new( metricsdir + '/charters-todo.txt', 'w+')
  @f_CHARTERS.puts "\"Session\"\t\"Field\"\t\"Value\""

  todo.each do |@file|
    parse_file
    parse_charter( 'todo' )
    parse_start( 'todo' )
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
    f_CHARTERS = File.new( metricsdir + '/charters-todo.txt', 'w')
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
    
    tester_data = []
    tester_data = dtcv_data[ tester ].sort { |x,y| (x[0] <=> y[0]) }
    
    data_points = tester_data.size
    
    if data_points > 1
      data_points.times do |x|
        if x + 1 < data_points
          
          tester_A = tester_data[ x ]
          tester_B = tester_data[ x + 1 ]
          
          first_start_time = Time.at( tester_A[1] )
          first_end_time = first_start_time + ( tester_A[2] * 60 )
          second_start_time = Time.at( tester_B[1] )
          
          if ( first_start_time == second_start_time )
            # Check for copy-and-paste errors - identical timestamps
            @errors_found = true
            output( "\n*** Error : START timestamps for two sessions are identical: \"#{ tester_A[ 0 ] }\" and \"#{ tester_B[ 0 ] }\"" )
          
          elsif ( second_start_time < ( first_end_time - (@timebox['allowable_session_overlap'] * 60) ) )
            # Check for session collisions - i.e. ones that start before the last one has ended (allowing for a configurable amount of overlap - e.g. 5 mins)
            @errors_found = true
            output( "\n*** Error : START timestamp in \"#{ tester_B[ 0 ] }\" begins *before* the previous session \"#{ tester_A[ 0 ] }\" has ended!" )
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
  
  f_CHARTERS = File.open( metricsdir + '/charters.txt' )
  f_CHARTERS.gets     # (ignore heading line)
  f_CHARTERS.each_line { |line| testarea[ line.split('"')[5] ] << line.split('"')[1]  if ( line.split('"')[3] == 'AREA' ) }     # ( testarea[ area ] << [session] )
  f_CHARTERS.close
end

testers = Hash.new { |h,k| h[k] = [] }

f_TESTERS = File.open( metricsdir + '/testers.txt' )
f_TESTERS.gets     # (ignore heading line)
f_TESTERS.each_line { |line| testers[ line.split('"')[3] ] << line.split('"')[1] }     # ( testers[ tester_name ] << [session] )
f_TESTERS.close

f_DAYBREAKS = File.new( metricsdir + '/breakdowns-day.txt', 'w' )
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
  date = value[0]
  n_total.has_key?( date ) ?        n_total[ date ] += value[8] :         n_total[ date ] = value[8]
  n_charter.has_key?( date ) ?      n_charter[ date ] += value[9] :       n_charter[ date ] = value[9]
  n_opportunity.has_key?( date ) ?  n_opportunity[ date ] += value[10] :  n_opportunity[ date ] = value[10]
  n_test.has_key?( date ) ?         n_test[ date ] += value[11] :         n_test[ date ] = value[11]
  n_bug.has_key?( date ) ?          n_bug[ date ] += value[12] :          n_bug[ date ] = value[12]
  n_prep.has_key?( date ) ?         n_prep[ date ] += value[13] :         n_prep[ date ] = value[13]
  bugs.has_key?( date ) ?           bugs[ date ] += value[14] :           bugs[ date ] = value[14]
  issues.has_key?( date ) ?         issues[ date ] += value[15] :         issues[ date ] = value[15]
end

n_total.sort { |a,b| Time.parse( b[0] ) <=> Time.parse( a[0] ) }.each do | date, value |     # (descending Date sort)
  f_DAYBREAKS.puts '"' + date + "\"\t\"" + 
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

f_TDAYBREAKS = File.new( metricsdir + '/breakdowns-tester-day.txt', 'w' )
f_TDAYBREAKS.puts "\"Tester\"\t\"Date\"\t\"Total\"\t\"On Charter\"\t\"Opportunity\"\t\"Test\"\t\"Bug\"\t\"Setup\"\t\"Bugs\"\t\"Issues\""

f_TESTERTOTALS = File.new( metricsdir + '/breakdowns-testers-total.txt', 'w' )
f_TESTERTOTALS.puts "\"Tester\"\t\"Total\"\t\"On Charter\"\t\"Opportunity\"\t\"Test\"\t\"Bug\"\t\"Setup\"\t\"Bugs\"\t\"Issues\""

f_TESTERBREAKS = File.new( metricsdir + '/breakdowns-testers-sessions.txt', 'w' )
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


testers.each do | tester_name, sess_arr |
  tn_total = {} ;        dn_total = {}
  tn_charter = {} ;      dn_charter = {}
  tn_opportunity = {} ;  dn_opportunity = {}
  tn_prep = {} ;         dn_prep = {}
  tn_test = {} ;         dn_test = {}
  tn_bug = {} ;          dn_bug = {}
  tn_tester = {} ;       dn_tester = {}
  tbugs = {} ;           dbugs = {}
  tissues = {} ;         dissues = {}
  
  sess_arr.each do | sess_name |
    start         = @sessions[ sess_name ][0]
    time          = @sessions[ sess_name ][1]
    duration      = @sessions[ sess_name ][2]
    oncharter     = @sessions[ sess_name ][3]
    onopportunity = @sessions[ sess_name ][4]
    test          = @sessions[ sess_name ][5]
    bug           = @sessions[ sess_name ][6]
    prep          = @sessions[ sess_name ][7]
    n_total       = @sessions[ sess_name ][8]
    n_charter     = @sessions[ sess_name ][9]
    n_opportunity = @sessions[ sess_name ][10]
    n_test        = @sessions[ sess_name ][11]
    n_bug         = @sessions[ sess_name ][12]
    n_prep        = @sessions[ sess_name ][13]
    bugs          = @sessions[ sess_name ][14].to_f     # (to help more accurately split counts between multiple testers)
    issues        = @sessions[ sess_name ][15].to_f
    testers       = @sessions[ sess_name ][16]
    
    f_TESTERBREAKS.puts '"' + sess_name + "\"\t\"" + 
      start + "\"\t\"" + 
      time + "\"\t\"" + 
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
    
    # As far as I can tell, these next lines are for f_TDAYBREAKS only
    # change the date format so it correctly sorts in 'yy/mm/dd' format -- we'll switch it back later when writing to file
    dnew_key = start[-2,2] + '/' + start[0,5] + "\t" + tester_name
    dn_total.has_key?( dnew_key ) ?        dn_total[ dnew_key ] += ( n_total/testers ) :             dn_total[ dnew_key ] = ( n_total/testers )
    dn_charter.has_key?( dnew_key ) ?      dn_charter[ dnew_key ] += ( n_charter/testers ) :         dn_charter[ dnew_key ] = ( n_charter/testers )
    dn_opportunity.has_key?( dnew_key ) ?  dn_opportunity[ dnew_key ] += ( n_opportunity/testers ) : dn_opportunity[ dnew_key ] = ( n_opportunity/testers )
    dn_test.has_key?( dnew_key ) ?         dn_test[ dnew_key ] += ( n_test/testers ) :               dn_test[ dnew_key ] = ( n_test/testers )
    dn_bug.has_key?( dnew_key ) ?          dn_bug[ dnew_key ] += ( n_bug/testers ) :                 dn_bug[ dnew_key ] = ( n_bug/testers )
    dn_prep.has_key?( dnew_key ) ?         dn_prep[ dnew_key ] += ( n_prep/testers ) :               dn_prep[ dnew_key ] = ( n_prep/testers )
    dbugs.has_key?( dnew_key ) ?           dbugs[ dnew_key ] += ( bugs/testers ) :                   dbugs[ dnew_key ] = ( bugs/testers )
    dissues.has_key?( dnew_key ) ?         dissues[ dnew_key ] += ( issues/testers ) :               dissues[ dnew_key ] = ( issues/testers )
    
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
    start = date_name.split(/\t/)[0]
    f_TDAYBREAKS.puts '"' + tester_name + "\"\t\"" + 
      start[-5,5] + '/' + start[0,2] + "\"\t\"" + 
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

  f_COVERAGEBREAKS = File.new( metricsdir + '/breakdowns-coverage-sessions.txt', 'w' )
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
  
  f_COVERAGETOTALS = File.new( metricsdir + '/breakdowns-coverage-total.txt', 'w' )
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
      sess_arr = testarea[ area ]
    else
      # (fill in blanks for the Coverage.ini Areas not yet covered)
      f_COVERAGEBREAKS.puts "\"\"\t" * 18 + '"' + area + '"'
      sess_arr = []
    end
    
    sess_arr.each do | sess_name |
      start         = @sessions[ sess_name ][0]
      time          = @sessions[ sess_name ][1]
      duration      = @sessions[ sess_name ][2]
      oncharter     = @sessions[ sess_name ][3]
      onopportunity = @sessions[ sess_name ][4]
      test          = @sessions[ sess_name ][5]
      bug           = @sessions[ sess_name ][6]
      prep          = @sessions[ sess_name ][7]
      n_total       = @sessions[ sess_name ][8]
      n_charter     = @sessions[ sess_name ][9]
      n_opportunity = @sessions[ sess_name ][10]
      n_test        = @sessions[ sess_name ][11]
      n_bug         = @sessions[ sess_name ][12]
      n_prep        = @sessions[ sess_name ][13]
      bugs          = @sessions[ sess_name ][14]
      issues        = @sessions[ sess_name ][15]
      testers       = @sessions[ sess_name ][16]
      
      f_COVERAGEBREAKS.puts '"' + sess_name + "\"\t\"" + 
        start + "\"\t\"" + 
        time + "\"\t\"" + 
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
@sessions.each { |file_name, data| resorted_array << file_name.to_a + data }
resorted_array.sort! { |a,b| Time.parse( b[1]+' '+b[2] ) <=> Time.parse( a[1]+' '+a[2] ) }

f_BREAKDOWNS = File.new( metricsdir + '/breakdowns.txt', 'w' )
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

resorted_array.each { |data| f_BREAKDOWNS.puts '"' + data.join("\"\t\"") + '"' }

f_BREAKDOWNS.close


## Final Note :
if @errors_found
  msg = "\nErrors Found!  Please correct the session sheet(s) listed above and re-run the scan utility."
else
  msg = 'Your papers are in order!'
end

output( msg )

### END ###