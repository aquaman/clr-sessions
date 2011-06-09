#! /usr/bin/env ruby
# -----
# search.rb
#
# Purpose: Search all the *.SES files in the specified folder for the specified search string
#
# Command Line Options :
# * 1 Required - directory with *.SES files to search
# * 1 Optional - where to put search results -- defaults to current directory
# -----
# Author:: Paul Carvalho
# Last Updated:: 08 June 2011
# Version:: 2.0
# -----

if ARGV[0].nil?
  puts "\nSearch all the *.SES files in a specified folder for specific keyword(s)"
  puts "\nUsage: #{File.basename($0)} scan_dir [output_dir]"
  puts "\n'scan_dir' is the path to the directory containing the session sheets"
  puts "[output_dir] = optional folder location to store search results"
  puts "(if left blank, will use current location = " + Dir.pwd + " )\n"
  exit
end

# determine the Output folder location (default = current location):
( ARGV[1].nil? ) ? output_dir = Dir.pwd : output_dir = ARGV[1]

# Check to make sure that the output folder specified exists:
unless FileTest.directory?( output_dir )
  puts '*'*50
  puts "Output location '" + output_dir + "' is not a valid directory!" 
  puts "Please check the name specified and try again."
  puts '*'*50
  exit
end


### METHODS ###

##
# Add matching session sheet contents to the output file
#
def concat( file_name )
  @f_CONCAT.puts <<EOF


###########################################################
Session: #{file_name}
!##########################################################

EOF
  @f_SHEET.rewind
  @f_SHEET.each_line {|line| @f_CONCAT.puts line }
end


### START ###

scan_dir = ARGV[0]

print "\nEnter the text to search for in '#{scan_dir}' : "
search_string = $stdin.gets.strip

exit if search_string.empty?

##
# Sort the file list - ET sessions chronologically, then alphabetical; followed by sorted TODO sessions, if any.
#
sheets = Dir[ scan_dir + '/*.ses' ]

todo_list = []
sheets.each {|x| todo_list << x  if ( x =~ /et-todo/ ) }
sheets.delete_if {|x| x =~ /et-todo/ } unless todo_list.empty?

sheets.sort! do |a,b|
  a_start = a =~ /\d{6}-/
  a_prefix = a.scan(/et-(\w{2,3})-/).to_s
  b_start = b =~ /\d{6}-/
  b_prefix = b.scan(/et-(\w{2,3})-/).to_s
  ( a[ a_start, 8] + a_prefix ) <=> ( b[ b_start, 8] + b_prefix )
end
sorted_files = sheets + todo_list.sort!

##
# Examine each file in the list for the search string. Stop searching a file at the first match found.
#

hits = 0
if sorted_files.empty?

  puts 'No session sheets found in the target folder specified.'

else

  @f_CONCAT = File.new( output_dir + '/search_results_sheets.txt', 'w' )
  f_BATCH = File.new( output_dir + '/open_search_results_sheets.bat', 'w' )
  f_BATCH.puts '@ECHO OFF'
  f_BATCH.puts ': This file was automatically created by "search.rb"'
  f_BATCH.puts ': The session sheets below match the search criteria:'
  f_BATCH.puts ': "' + search_string + '"'
  f_BATCH.puts ':'

  match_found = false
  sorted_files.each do | file |
    @f_SHEET = File.open( file )
    match_found = false
    while ( line = @f_SHEET.gets ) and ( ! match_found )
      if ( line =~ /#{search_string}/io)
        f_BATCH.puts 'start notepad ' + File.expand_path( file )
        concat( file )
        hits += 1
        match_found = true
      end
    end
    @f_SHEET.close
  end

  if hits.zero?
    f_BATCH.puts ': <no matches found>'
    @f_CONCAT.puts 'no matches found'
  end

end

puts "\n#{hits} file(s) were found that matched your search."

unless hits.zero?
  puts "\nType 'open_search_results_sheets.bat' to view each matching file in Notepad."
  puts "Open 'search_results_sheets.txt' to view the contents of all the matching files together."
end

### END ###