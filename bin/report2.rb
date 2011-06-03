#! /usr/bin/env ruby
# -----
# report2.rb
#
# Purpose: Generate HTML reports based upon the data files created by the SCAN.RB script
#
# NOTE: This HTML report links to the session sheets in the 'approved' folder location (which is assumed to be at the same folder level as the 'reports' folder)
#--
# TODO: remove the dependency of the HTML reports on the hard-coded path location to the Session sheets.
# * Maybe add another command-line option to pass the folder location of the 'approved' session sheets?
# * Maybe read the session folder location from the SBTM.YML file?
#++
#
# Command Line Options : 1 Required - the SBTM.YML directory location
#
# -----
# Author:: Paul Carvalho
# Last Updated:: 03 June 2011
# Version:: 2.0
# -----
@ScriptName = File.basename($0)

if ARGV[0].nil? or ! File.exist?( ARGV[0] + '/sbtm.yml' )
  puts "\nUsage: #{@ScriptName} config_dir"
  puts "\nWhere: 'config_dir' is the path to the directory containing SBTM.YML\n"
  exit
end

# Load some needed libraries
require 'yaml'
require 'Time' unless Time.methods.include? 'parse'

# Read the Configuration file:
config = YAML.load_file( ARGV[0] + '/sbtm.yml' )

begin
  template_dir = config['folders']['report_templates']
  metrics_dir = config['folders']['metrics_dir']
  @report_dir = config['folders']['report_dir']
  
  @timebox = config['timebox']
  @include_switch = config['scan_options']
  
  raise if template_dir.nil? or metrics_dir.nil? or @report_dir.nil? or @timebox.nil? or @include_switch.nil?
rescue
  puts '*'*50
  puts 'Error reading value from SBTM.YML!'
  puts '*'*50
  exit
end

# CHECK that the file directories specified appear to be valid:
[ template_dir, metrics_dir, @report_dir ].each do |folder|
  unless FileTest.directory?( folder )
    puts '*'*50
    puts "'" + folder + "' is not a valid directory!" 
    puts "Please check the name specified in SBTM.YML and try again."
    puts '*'*50
    exit
  end
end


### METHODS ###

##
# Exit the script gracefully if it encounters an error trying to open a file.
#
# Print a friendly message and include the script line number where it failed.
#
def die( parting_thought, line_num )
  puts  @ScriptName + ': ' + parting_thought + ": line ##{line_num}"
  exit
end

##
# Create the Coverage Totals page
#
# It takes 2 parameters:
# * _title_ = the filename
# * _sortby_ = the table column to sort the data by
# Data is based on the content of 'breakdowns-coverage-total.txt'
#
def make_coverage( title, sortby )
  if ( sortby != 8)
    @fields.sort! { |a,b| b[ sortby ].to_f <=> a[ sortby ].to_f }     # (i.e. descending sort)
  else
    @fields.sort! { |a,b| a[ sortby ] <=> b[ sortby ] }     # (i.e. ascending sort)
  end
  
  @f_TCOVER.rewind
  @f_COVER = File.new(@report_dir + "/#{title}", 'w') rescue die( "Can't open #{@report_dir}\\#{title}", __LINE__ )

  while ( line = @f_TCOVER.gets )
    if ( line =~ /^table data goes here/ )
      get_coverline
    elsif ( line =~ /^Report current.*/ )
      @f_COVER.puts "Report current as of: #{@thedate}"
    elsif ( line =~ /about 90 minutes/ )
      # edit the line and insert the actual 'Normal' value from the config file
      line['90'] = @timebox['normal'].to_s
      @f_COVER.puts line
    elsif ( line =~ /^table header goes here/)
      # print only the column headings we need
      @f_COVER.puts '    <td width="6%"><b><font face="Arial"><a href="c_by_total.htm">TOTAL</a></font></b></td>' if @include_switch['Duration']
      @f_COVER.puts '    <td width="6%"><b><font face="Arial"><a href="c_by_chtr.htm">CHTR</a></font></b></td>' if @include_switch['C vs O']
      @f_COVER.puts '    <td width="6%"><b><font face="Arial"><a href="c_by_opp.htm">OPP</a></font></b></td>' if @include_switch['C vs O']
      @f_COVER.puts '    <td width="6%"><b><font face="Arial"><a href="c_by_test.htm">TEST</a></font></b></td>' if @include_switch['TBS']
      @f_COVER.puts '    <td width="7%"><b><font face="Arial"><a href="c_by_bug.htm">BUG</a></font></b></td>' if @include_switch['TBS']
      @f_COVER.puts '    <td width="7%"><b><font face="Arial"><a href="c_by_setup.htm">SETUP</a></font></b></td>' if @include_switch['TBS']
    else
      @f_COVER.puts line
    end
  end
  
  @f_COVER.close
end

##
# Get a line of coverage data from 'breakdowns-coverage-total.txt'
#
def get_coverline
  @fields.each_index do |row|
    @total = @fields[ row ][0] if @include_switch['Duration']
    @chtr = @fields[ row ][1] if @include_switch['C vs O']
    @opp = @fields[ row ][2] if @include_switch['C vs O']
    @test = @fields[ row ][3] if @include_switch['TBS']
    @bug = @fields[ row ][4] if @include_switch['TBS']
    @setup = @fields[ row ][5] if @include_switch['TBS']
    @bugs = @fields[ row ][6]
    @issues = @fields[ row ][7]
    @area = @fields[ row ][8]
    post_coverline( row.to_f )
  end
end

##
# Print a line of coverage data in HTML table format. Print the column data only if the field is included in the SBTM.YML file.
#
# This method takes 'row_num' parameter simply to alternate the table row colours - between white and yellow
#
def post_coverline( row_num )
  ( row_num/2 ) == ( row_num/2 ).to_i ? bkgd_clr = '' : bkgd_clr = 'bgcolor="#FFFFCC"'
  @f_COVER.puts "  <tr #{bkgd_clr}>"
  @f_COVER.puts "    <td width=\"6%\"><font face=\"Courier New\" size=\"2\">#{@total}</font></td>" if @include_switch['Duration']
  @f_COVER.puts "    <td width=\"6%\"><font face=\"Courier New\" size=\"2\">#{@chtr}</font></td>" if @include_switch['C vs O']
  @f_COVER.puts "    <td width=\"6%\"><font face=\"Courier New\" size=\"2\">#{@opp}</font></td>" if @include_switch['C vs O']
  @f_COVER.puts "    <td width=\"6%\"><font face=\"Courier New\" size=\"2\">#{@test}</font></td>" if @include_switch['TBS']
  @f_COVER.puts "    <td width=\"7%\"><font face=\"Courier New\" size=\"2\">#{@bug}</font></td>" if @include_switch['TBS']
  @f_COVER.puts "    <td width=\"7%\"><font face=\"Courier New\" size=\"2\">#{@setup}</font></td>" if @include_switch['TBS']
  @f_COVER.puts "    <td width=\"7%\" ALIGN=\"center\"><font face=\"Courier New\" size=\"2\">#{@bugs}</font></td>"
  @f_COVER.puts "    <td width=\"7%\" ALIGN=\"center\"><font face=\"Courier New\" size=\"2\">#{@issues}</font></td>"
  @f_COVER.puts "    <td width=\"48%\"><font face=\"Courier New\" size=\"2\">#{@area}</font></td>"
  @f_COVER.puts "  </tr>"
end

##
# Create the Completed Session Sheets page
#
# It takes 2 parameters:
# * _title_ = the filename
# * _sortby_ = the table column to sort the data by
# Data is based on the content of 'breakdowns.txt'
#
def make_session( title, sortby )
  if ( sortby == 0 )
    @fields.sort! { |a,b| a[ sortby ] <=> b[ sortby ] }     # (i.e. ascending sort)
  elsif ( sortby == 1 )
    @fields.sort! {|a,b| Time.parse( b[1]+' '+b[2] ) <=> Time.parse( a[1]+' '+a[2] ) }     # (i.e. descending date+time sort)
  elsif ( sortby == 2 )
    @fields.sort! {|a,b| Time.parse( b[ sortby ] ) <=> Time.parse( a[ sortby ] ) }     # (i.e. descending time sort)
  else  # ( sortby > 2 )
    @fields.sort! { |a,b| b[ sortby ].to_f <=> a[ sortby ].to_f }     # (i.e. descending numeric sort)
  end
  
  @f_TSES.rewind
  @f_SES = File.new(@report_dir + "/#{title}", 'w') rescue die( "Can't open #{@report_dir}\\#{title}", __LINE__ )
  
  while ( line = @f_TSES.gets )
    if ( line =~ /^table data goes here/)
      get_session_line
    elsif ( line =~ /^Report current.*/)
      @f_SES.puts "Report current as of: #{@thedate}"
    elsif ( line =~ /about 90 minutes/ )
      # edit the line and insert the actual 'Normal' value from the config file
      line['90'] = @timebox['normal'].to_s
      @f_SES.puts line
    elsif ( line =~ /^table header goes here/)
      # print only the column headings we need
      @f_SES.puts '    <th><font face="Arial"><a href="s_by_dur.htm">DUR</a></font></th>' if @include_switch['Duration']
      @f_SES.puts '    <th><font face="Arial"><a href="s_by_chtr.htm">CHTR</a></font></th>' if @include_switch['C vs O']
      @f_SES.puts '    <th><font face="Arial"><a href="s_by_opp.htm">OPP</a></font></th>' if @include_switch['C vs O']
      @f_SES.puts '    <th><font face="Arial"><a href="s_by_test.htm">TEST</a></font></th>' if @include_switch['TBS']
      @f_SES.puts '    <th><font face="Arial"><a href="s_by_bug.htm">BUG</a></font></th>' if @include_switch['TBS']
      @f_SES.puts '    <th><font face="Arial"><a href="s_by_setup.htm">SETUP</a></font></th>' if @include_switch['TBS']
    else
      @f_SES.puts line
    end
  end

  @f_SES.close
end

##
# Get a line of session data from 'breakdowns.txt'
#
def get_session_line
  @fields.each_index do |row|
    @session = "<a href=\"..\\approved\\#{@fields[ row ][ 0]}\">#{@fields[ row ][ 0][0..-5]}</a>"
    @date = @fields[ row ][ 1]
    @time = @fields[ row ][ 2]
    @dur = @fields[ row ][ 3] if @include_switch['Duration']
    @chtr = @fields[ row ][ 4] if @include_switch['C vs O']
    @opp = @fields[ row ][ 5] if @include_switch['C vs O']
    @test = @fields[ row ][ 6] if @include_switch['TBS']
    @bug = @fields[ row ][ 7] if @include_switch['TBS']
    @setup = @fields[ row ][ 8] if @include_switch['TBS']
    @bugs = @fields[ row ][ 9]
    @issues = @fields[ row ][10]
    @tstrs = @fields[ row ][11]
    post_session_line( row.to_f )
  end
end

##
# Print a line of session data in HTML table format. Print the column data only if the field is included in the SBTM.YML file.
#
# This method takes 'row_num' parameter simply to alternate the table row colours - between white and yellow
#
def post_session_line( row_num )
  ( row_num/2 ) == ( row_num/2 ).to_i ? bkgd_clr = '' : bkgd_clr = 'bgcolor="#FFFFCC"'
  @f_SES.puts "  <tr #{bkgd_clr}>"
  @f_SES.puts "    <td><font face=\"Courier New\" size=\"2\">#{@session}</font></td>"
  @f_SES.puts "    <td ALIGN=\"center\"><font face=\"Courier New\" size=\"2\">#{@date}</font></td>"
  @f_SES.puts "    <td ALIGN=\"center\"><font face=\"Courier New\" size=\"2\">#{@time}</font></td>"
  @f_SES.puts "    <td><font face=\"Courier New\" size=\"2\">#{@dur}</font></td>" if @include_switch['Duration']
  @f_SES.puts "    <td><font face=\"Courier New\" size=\"2\">#{@chtr}</font></td>" if @include_switch['C vs O']
  @f_SES.puts "    <td><font face=\"Courier New\" size=\"2\">#{@opp}</font></td>" if @include_switch['C vs O']
  @f_SES.puts "    <td><font face=\"Courier New\" size=\"2\">#{@test}</font></td>" if @include_switch['TBS']
  @f_SES.puts "    <td><font face=\"Courier New\" size=\"2\">#{@bug}</font></td>" if @include_switch['TBS']
  @f_SES.puts "    <td><font face=\"Courier New\" size=\"2\">#{@setup}</font></td>" if @include_switch['TBS']
  @f_SES.puts "    <td ALIGN=\"center\"><font face=\"Courier New\" size=\"2\">#{@bugs}</font></td>"
  @f_SES.puts "    <td ALIGN=\"center\"><font face=\"Courier New\" size=\"2\">#{@issues}</font></td>"
  if @tstrs.to_i == 1
    @f_SES.puts "    <td ALIGN=\"center\"><font face=\"Courier New\" size=\"2\">#{@tstrs}</font></td>"
  else
    @f_SES.puts "    <td ALIGN=\"center\"><font face=\"Courier New\" size=\"2\"><font color=\"red\">#{@tstrs}</font></font></td>"
  end
  @f_SES.puts "  </tr>"
end

##
# Format numbers consistently:
# * show no decimals if it is a whole number (integer)
# * otherwise round it up to the nearest 2 decimal places
#
def format_num( tmp_arr )
  tmp_arr.collect! do |x|
    if ( ( x.to_f.to_s == x ) and ( x.to_f == x.to_i ) )     # (integer value - no decimals)
      x.to_i.to_s
    elsif ( x.to_f.to_s == x )     # (decimal value - format to 2 decimals)
      sprintf("%0.2f", x)
    else
      x
    end
  end
end

### START ###

f_TSTATUS = File.open(template_dir + '/status.tpl') rescue die( "Can't open #{template_dir}\\status.tpl", __LINE__ )
f_STATUS = File.new(@report_dir + '/status.htm', 'w') rescue die( "Can't open #{@report_dir}\\status.htm", __LINE__ )
f_BREAKS = File.open(metrics_dir + '/breakdowns.txt') rescue die( "Can't open #{metrics_dir}\\breakdowns.txt", __LINE__ )

##
# Create the main "Session Summary" page

@thedate = Time.now.strftime("%d %B %Y %H:%M")   # (** Customise the time format to your heart's content! **)
@fields = []

f_BREAKS.gets     # (skip the first header line)
sessioncount, totalsessions, totalbugs = 0, 0, 0

while ( line = f_BREAKS.gets )
  values = line.split(/\"/).delete_if {|x| x.strip.empty? }
  sessioncount += 1
  totalsessions += values[9].to_f     # ( = "N Total")
  totalbugs += values[15].to_i     # ( = "Bugs")
  @fields << format_num( values )
end

while ( line = f_TSTATUS.gets )
  if ( line =~ /^ Updated:.*/ )
    f_STATUS.puts " Updated: #{@thedate}"
  elsif ( line =~ /^Sessions:.*/ )
    totalsessions = sprintf( "%0.2f", totalsessions ) 
    f_STATUS.puts "Sessions: #{totalsessions} (#{sessioncount} reports)"
  elsif ( line =~ /^    Bugs:.*/ )
    f_STATUS.puts "    Bugs: #{totalbugs}"
  elsif ( line =~ /View Test Coverage/ )
    if @include_switch['Areas']
      if @include_switch['Duration']
        f_STATUS.puts line
      else
        # change the default report link if #Duration is skipped
        f_STATUS.puts line.gsub('_total.', '_area.')
      end
    else
      f_STATUS.puts '<h3>View Test Coverage - <em>Skipped (#Areas not included)</em></h3>'
    end
  else
    f_STATUS.puts line
  end
end

f_BREAKS.close
f_STATUS.close
f_TSTATUS.close

##
# Create the "Completed Session Reports" pages (with column heading resorting)

@fields.each do |values|
  6.times { values.delete_at(3) }     # (remove the columns we don't need)
end

@f_TSES = File.open(template_dir + '/sessions.tpl') rescue die( "Can't open #{template_dir}\\sessions.tpl", __LINE__ )

make_session('s_by_ses.htm', 0)
make_session('s_by_datetime.htm', 1)
make_session('s_by_time.htm', 2)
make_session('s_by_dur.htm', 3) if @include_switch['Duration']
make_session('s_by_chtr.htm', 4) if @include_switch['C vs O']
make_session('s_by_opp.htm', 5) if @include_switch['C vs O']
make_session('s_by_test.htm', 6) if @include_switch['TBS']
make_session('s_by_bug.htm', 7) if @include_switch['TBS']
make_session('s_by_setup.htm', 8) if @include_switch['TBS']
make_session('s_by_bugs.htm', 9)
make_session('s_by_issues.htm', 10)
make_session('s_by_testers.htm', 11)

@f_TSES.close

##
# Create the "Test Coverage Totals" pages (with column heading resorting) - only if the #Areas section is included

if @include_switch['Areas']
  f_DATA = File.open(metrics_dir + '/breakdowns-coverage-total.txt') rescue die( "Can't open #{metrics_dir}\\breakdowns-coverage-total.txt", __LINE__ )

  f_DATA.gets     # (skip the first header line)
  @fields = []
  while ( line = f_DATA.gets )
    rawfields = line.split(/\"/).delete_if {|x| x.strip.empty? }
    @fields << format_num( rawfields )
  end
  f_DATA.close

  @f_TCOVER = File.open(template_dir + '/coverage.tpl') rescue die( "Can't open #{template_dir}\\coverage.tpl", __LINE__ )

  make_coverage('c_by_total.htm', 0) if @include_switch['Duration']
  make_coverage('c_by_chtr.htm', 1) if @include_switch['C vs O']
  make_coverage('c_by_opp.htm', 2) if @include_switch['C vs O']
  make_coverage('c_by_test.htm', 3) if @include_switch['TBS']
  make_coverage('c_by_bug.htm', 4) if @include_switch['TBS']
  make_coverage('c_by_setup.htm', 5) if @include_switch['TBS']
  make_coverage('c_by_bugs.htm', 6)
  make_coverage('c_by_issues.htm', 7)
  make_coverage('c_by_area.htm', 8)

  @f_TCOVER.close
end

### END ###