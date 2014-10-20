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
# * Maybe read the session folder location from the SBT_CONFIG.YML file?
#++
#
# Command Line Options : 1 Required - the SBT_CONFIG.YML directory location
#
# -----
# Copyright (C) 2014 Paul Carvalho
#
# This program is free software and is distributed under the same terms as the Ruby GPL.
# See LICENSE.txt in the 'doc' folder for more information.
#
# Last Updated:: 19 October 2014
# Version:: 2.2
# -----

require 'yaml'
require 'date'
require 'time'

class GenerateHTMLReports

  def initialize
    @script_name = File.basename($0)

    if ARGV[0].nil? or !File.exist?(ARGV[0] + '/sbt_config.yml')
      puts "\nUsage: #{@script_name} config_dir"
      puts "\nWhere: 'config_dir' is the path to the directory containing SBT_CONFIG.YML\n"
      exit
    end
  end

  ##
  # Exit gracefully and show a message indicating what failed. The 'message' parameter is an array.
  #
  def setup_fail(message)
    puts '-'*50
    message.each { |line| puts line }
    puts '-'*50
    exit
  end

  def check_config_settings
    begin
      config = YAML.load_file(ARGV[0] + '/sbt_config.yml')

      @template_dir = config['folders']['report_templates']
      @metrics_dir = config['folders']['metrics_dir']
      @report_dir = config['folders']['report_dir']

      @timebox = config['timebox']
      @include_switch = config['scan_options']

      raise if @template_dir.nil? or @metrics_dir.nil? or @report_dir.nil? or @timebox.nil? or @include_switch.nil?
    rescue
      setup_fail ['Error reading value from SBT_CONFIG.YML!']
    end

    # CHECK that the file directories specified appear to be valid:
    [@template_dir, @metrics_dir, @report_dir].each do |folder|
      unless FileTest.directory?(folder)
        message = []
        message << "'" + folder + "' is not a valid directory!"
        message << 'Please check the name specified in SBT_CONFIG.YML and try again.'
        setup_fail message
      end
    end

  end

  ##
  # Exit the script gracefully if it encounters an error trying to open a file.
  #
  # Print a friendly message and include the script line number where it failed.
  #
  def die(parting_thought, line_num)
    puts @script_name + ': ' + parting_thought + ": line ##{line_num}"
    exit
  end

  ##
  # Some HTML formatting shortcuts
  #
  def indent1
    ' ' * 2
  end
  def indent2
    indent1 * 2
  end

  ##
  # Create the Coverage Totals page
  #
  # It takes 2 parameters:
  # * _title_ = the filename
  # * _sortby_ = the table column to sort the data by
  # Data is based on the content of 'breakdowns-coverage-total.txt'
  #
  def make_coverage(title, sortby)
    if (sortby != 8)
      @fields.sort! { |a, b| b[sortby].to_f <=> a[sortby].to_f } # (i.e. descending sort)
    else
      @fields.sort! { |a, b| a[sortby] <=> b[sortby] } # (i.e. ascending sort)
    end

    @file_coverage_template.rewind
    file_coverage = File.new(@report_dir + "/#{title}", 'w') rescue die("Can't open #{@report_dir}\\#{title}", __LINE__)

    while (line = @file_coverage_template.gets)
      if (line =~ /^table data goes here/)
        get_coverline(file_coverage)
      elsif (line =~ /^Report current.*/)
        file_coverage.puts 'Report current as of: ' + @report_timestamp
      elsif (line =~ /about 90 minutes/)
        # edit the line and insert the actual 'Normal' value from the config file
        line['90'] = @timebox['normal'].to_s
        file_coverage.puts line
      elsif (line =~ /^table header goes here/)
        # print only the column headings we need
        file_coverage.puts indent2 + '<th width="7%"><font face="Arial"><a href="cov_by_total.htm">TOTAL</a></font></th>' if @include_switch['Duration']
        file_coverage.puts indent2 + '<th width="7%"><font face="Arial"><a href="cov_by_charter.htm">CHTR</a></font></th>' if @include_switch['C vs O']
        file_coverage.puts indent2 + '<th width="7%"><font face="Arial"><a href="cov_by_opp.htm">OPP</a></font></th>' if @include_switch['C vs O']
        file_coverage.puts indent2 + '<th width="8%"><font face="Arial"><a href="cov_by_test.htm">% TEST</a></font></th>' if @include_switch['TBS']
        file_coverage.puts indent2 + '<th width="7%"><font face="Arial"><a href="cov_by_bug.htm">% BUG</a></font></th>' if @include_switch['TBS']
        file_coverage.puts indent2 + '<th width="8%"><font face="Arial"><a href="cov_by_setup.htm">% SETUP</a></font></th>' if @include_switch['TBS']
      else
        file_coverage.puts line
      end
    end

    file_coverage.close
  end

  ##
  # Get a line of coverage data from 'breakdowns-coverage-total.txt'
  # Print a line of coverage data in HTML table format.
  # Print the column data only if the field is included in the SBT_CONFIG.YML file.
  # This method alternates the table row colours - between white and yellow - for readability
  #
  def get_coverline(output_file)
    @fields.each_index do |row|
      (row.to_f/2) == (row.to_f/2).to_i ? background_colour = '' : background_colour = 'bgcolor="#FFFFCC"'
      output_file.puts indent1 + "<tr #{background_colour}>"

      row_data = @fields[row]
      output_file.puts indent2 + "<td><font face=\"Courier New\" size=\"2\">#{row_data[0]}</font></td>" if @include_switch['Duration']
      output_file.puts indent2 + "<td><font face=\"Courier New\" size=\"2\">#{row_data[1]}</font></td>" if @include_switch['C vs O']
      output_file.puts indent2 + "<td><font face=\"Courier New\" size=\"2\">#{row_data[2]}</font></td>" if @include_switch['C vs O']
      output_file.puts indent2 + "<td><font face=\"Courier New\" size=\"2\">#{row_data[3]}</font></td>" if @include_switch['TBS']
      output_file.puts indent2 + "<td><font face=\"Courier New\" size=\"2\">#{row_data[4]}</font></td>" if @include_switch['TBS']
      output_file.puts indent2 + "<td><font face=\"Courier New\" size=\"2\">#{row_data[5]}</font></td>" if @include_switch['TBS']
      output_file.puts indent2 + "<td ALIGN=\"center\"><font face=\"Courier New\" size=\"2\">#{row_data[6]}</font></td>"
      output_file.puts indent2 + "<td ALIGN=\"center\"><font face=\"Courier New\" size=\"2\">#{row_data[7]}</font></td>"
      output_file.puts indent2 + "<td><font face=\"Courier New\" size=\"2\">#{row_data[8]}</font></td>"
      output_file.puts indent1 + '</tr>'
    end
  end

  ##
  # Create the Completed Session Sheets page
  #
  # It takes 2 parameters:
  # * _title_ = the filename
  # * _sortby_ = the table column to sort the data by
  # Data is based on the content of 'breakdowns.txt'
  #
  def make_session(title, sortby)
    if (sortby == 0)
      @fields.sort! { |a, b| a[sortby] <=> b[sortby] } # (i.e. ascending sort)
    elsif (sortby == 1)
      @fields.sort! { |a, b| DateTime.parse(b[1]+' '+b[2]) <=> DateTime.parse(a[1]+' '+a[2]) } # (i.e. descending date+time sort)
    elsif (sortby == 2)
      @fields.sort! { |a, b| Time.parse(b[sortby]) <=> Time.parse(a[sortby]) } # (i.e. descending time sort)
    else # ( sortby > 2 )
      @fields.sort! { |a, b| b[sortby].to_f <=> a[sortby].to_f } # (i.e. descending numeric sort)
    end

    @file_session_template.rewind
    file_sessions = File.new(@report_dir + "/#{title}", 'w') rescue die("Can't open #{@report_dir}\\#{title}", __LINE__)

    while (line = @file_session_template.gets)
      if (line =~ /^table data goes here/)
        get_session_line(file_sessions)
      elsif (line =~ /^Report current.*/)
        file_sessions.puts 'Report current as of: ' + @report_timestamp
      elsif (line =~ /about 90 minutes/)
        # edit the line and insert the actual 'Normal' value from the config file
        line['90'] = @timebox['normal'].to_s
        file_sessions.puts line
      elsif (line =~ /^table header goes here/)
        # print only the column headings we need
        file_sessions.puts indent2 + '<th><font face="Arial"><a href="sess_by_duration.htm">DUR</a></font></th>' if @include_switch['Duration']
        file_sessions.puts indent2 + '<th><font face="Arial"><a href="sess_by_charter.htm">CHTR</a></font></th>' if @include_switch['C vs O']
        file_sessions.puts indent2 + '<th><font face="Arial"><a href="sess_by_opp.htm">OPP</a></font></th>' if @include_switch['C vs O']
        file_sessions.puts indent2 + '<th><font face="Arial"><a href="sess_by_test.htm">% TEST</a></font></th>' if @include_switch['TBS']
        file_sessions.puts indent2 + '<th><font face="Arial"><a href="sess_by_bug.htm">% BUG</a></font></th>' if @include_switch['TBS']
        file_sessions.puts indent2 + '<th><font face="Arial"><a href="sess_by_setup.htm">% SETUP</a></font></th>' if @include_switch['TBS']
      else
        file_sessions.puts line
      end
    end

    file_sessions.close
  end

  ##
  # Get a line of session data from 'breakdowns.txt'
  # Print a line of session data in HTML table format.
  # Print the column data only if the field is included in the SBT_CONFIG.YML file.
  # This method alternates the table row colours - between white and yellow - for readability
  #
  def get_session_line(output_file)
    @fields.each_index do |row|

      (row.to_f/2) == (row.to_f/2).to_i ? background_colour = '' : background_colour = 'bgcolor="#FFFFCC"'
      output_file.puts indent1 + "<tr #{background_colour}>"

      row_data = @fields[row]
      session_id = "<a href=\"..\\approved\\#{row_data[0]}\">#{row_data[0][0..-5]}</a>"
      output_file.puts indent2 + "<td><font face=\"Courier New\" size=\"2\">#{session_id}</font></td>"
      output_file.puts indent2 + "<td ALIGN=\"center\"><font face=\"Courier New\" size=\"2\">#{row_data[1]}</font></td>"
      output_file.puts indent2 + "<td ALIGN=\"center\"><font face=\"Courier New\" size=\"2\">#{row_data[2]}</font></td>"
      output_file.puts indent2 + "<td><font face=\"Courier New\" size=\"2\">#{row_data[3]}</font></td>" if @include_switch['Duration']
      output_file.puts indent2 + "<td><font face=\"Courier New\" size=\"2\">#{row_data[4]}</font></td>" if @include_switch['C vs O']
      output_file.puts indent2 + "<td><font face=\"Courier New\" size=\"2\">#{row_data[5]}</font></td>" if @include_switch['C vs O']
      output_file.puts indent2 + "<td><font face=\"Courier New\" size=\"2\">#{row_data[6]}</font></td>" if @include_switch['TBS']
      output_file.puts indent2 + "<td><font face=\"Courier New\" size=\"2\">#{row_data[7]}</font></td>" if @include_switch['TBS']
      output_file.puts indent2 + "<td><font face=\"Courier New\" size=\"2\">#{row_data[8]}</font></td>" if @include_switch['TBS']
      output_file.puts indent2 + "<td ALIGN=\"center\"><font face=\"Courier New\" size=\"2\">#{row_data[9]}</font></td>"
      output_file.puts indent2 + "<td ALIGN=\"center\"><font face=\"Courier New\" size=\"2\">#{row_data[10]}</font></td>"
      num_testers = row_data[11].to_i
      if num_testers == 1
        output_file.puts indent2 + "<td ALIGN=\"center\"><font face=\"Courier New\" size=\"2\">#{num_testers}</font></td>"
      else
        output_file.puts indent2 + "<td ALIGN=\"center\"><font face=\"Courier New\" size=\"2\"><font color=\"red\">#{num_testers}</font></font></td>"
      end
      output_file.puts indent1 + '</tr>'
    end
  end

  ##
  # Format numbers consistently:
  # * show no decimals if it is a whole number (integer)
  # * otherwise round it up to the nearest 2 decimal places
  #
  def format_num(tmp_arr)
    tmp_arr.collect! do |x|
      if ((x.to_f.to_s == x) and (x.to_f == x.to_i)) # (integer value - no decimals)
        x.to_i.to_s
      elsif (x.to_f.to_s == x) # (decimal value - format to 2 decimals)
        sprintf('%0.2f', x)
      else
        x
      end
    end
  end

  ##
  # Customise the date & time format to your heart's content!
  #
  def get_timestamp
    Time.now.strftime('%d %B %Y %H:%M')
  end

  def create_session_summary
    file_status_template = File.open(@template_dir + '/status.tpl') rescue die("Can't open #{@template_dir}\\status.tpl", __LINE__)
    file_status_html = File.new(@report_dir + '/status.htm', 'w') rescue die("Can't open #{@report_dir}\\status.htm", __LINE__)
    file_breakdowns = File.open(@metrics_dir + '/breakdowns.txt') rescue die("Can't open #{@metrics_dir}\\breakdowns.txt", __LINE__)

    @fields = []

    file_breakdowns.gets # (skip the first header line)
    sessioncount, totalsessions, totalbugs = 0, 0, 0

    while (line = file_breakdowns.gets)
      values = line.split('"').delete_if { |x| x.strip.empty? }
      sessioncount += 1
      totalsessions += values[9].to_f # ( = "N Total")
      totalbugs += values[15].to_i # ( = "Bugs")
      @fields << format_num(values)
    end

    while (line = file_status_template.gets)
      print_line = ''
      if (line =~ /^ Updated:.*/)
        print_line = ' Updated: ' + @report_timestamp
      elsif (line =~ /^Sessions:.*/)
        totalsessions = sprintf('%0.2f', totalsessions)
        print_line = "Sessions: #{totalsessions} (#{sessioncount} reports)"
      elsif (line =~ /^    Bugs:.*/)
        print_line = "    Bugs: #{totalbugs}"
      elsif (line =~ /View Test Coverage/)
        if @include_switch['Areas']
          if @include_switch['Duration']
            print_line = line
          else
            # change the default report link if #Duration is skipped
            print_line = line.gsub('_total.', '_area.')
          end
        else
          print_line = '<h3>View Test Coverage - <em>Skipped (#Areas not included)</em></h3>'
        end
      else
        print_line = line
      end
      file_status_html.puts print_line
    end

    file_breakdowns.close
    file_status_html.close
    file_status_template.close
  end

  def create_completed_sessions
    @fields.each do |values|
      6.times { values.delete_at(3) } # (remove the columns we don't need)
    end

    @file_session_template = File.open(@template_dir + '/sessions.tpl') rescue die("Can't open #{@template_dir}\\sessions.tpl", __LINE__)

    make_session('sess_by_ses.htm', 0)
    make_session('sess_by_datetime.htm', 1)
    make_session('sess_by_time.htm', 2)
    make_session('sess_by_duration.htm', 3) if @include_switch['Duration']
    make_session('sess_by_charter.htm', 4) if @include_switch['C vs O']
    make_session('sess_by_opp.htm', 5) if @include_switch['C vs O']
    make_session('sess_by_test.htm', 6) if @include_switch['TBS']
    make_session('sess_by_bug.htm', 7) if @include_switch['TBS']
    make_session('sess_by_setup.htm', 8) if @include_switch['TBS']
    make_session('sess_by_num_bugs.htm', 9)
    make_session('sess_by_num_issues.htm', 10)
    make_session('sess_by_num_testers.htm', 11)

    @file_session_template.close
  end

  def create_test_coverage_totals
    file_data = File.open(@metrics_dir + '/breakdowns-coverage-total.txt') rescue die("Can't open #{@metrics_dir}\\breakdowns-coverage-total.txt", __LINE__)

    file_data.gets # (skip the first header line)
    @fields = []
    while (line = file_data.gets)
      rawfields = line.split('"').delete_if { |x| x.strip.empty? }
      @fields << format_num(rawfields)
    end
    file_data.close

    @file_coverage_template = File.open(@template_dir + '/coverage.tpl') rescue die("Can't open #{@template_dir}\\coverage.tpl", __LINE__)

    make_coverage('cov_by_total.htm', 0) if @include_switch['Duration']
    make_coverage('cov_by_charter.htm', 1) if @include_switch['C vs O']
    make_coverage('cov_by_opp.htm', 2) if @include_switch['C vs O']
    make_coverage('cov_by_test.htm', 3) if @include_switch['TBS']
    make_coverage('cov_by_bug.htm', 4) if @include_switch['TBS']
    make_coverage('cov_by_setup.htm', 5) if @include_switch['TBS']
    make_coverage('cov_by_num_bugs.htm', 6)
    make_coverage('cov_by_num_issues.htm', 7)
    make_coverage('cov_by_area.htm', 8)

    @file_coverage_template.close
  end


  ##
  # Start here
  #
  def run
    check_config_settings

    @report_timestamp = get_timestamp

    # Create the main "Session Summary" page
    create_session_summary

    # Create the "Completed Session Reports" pages (with column heading resorting)
    create_completed_sessions

    # Create the "Test Coverage Totals" pages (with column heading resorting)
    # - only if the #Areas section is included
    create_test_coverage_totals if @include_switch['Areas']

  end

end

GenerateHTMLReports.new.run

### END ###