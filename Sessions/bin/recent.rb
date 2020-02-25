#! /usr/bin/env ruby
#-------------------------------------------------------------------------------------------------------------#
# recent.rb
# Command Line Options : 1 Optional - a number
# Purpose: to produce a quick summary of the data in the BREAKDOWNS-DAY.TXT file
#    for the number of days specified (default = last 1 day)
#
# Ported from the original PERL script (dated 18-May-2001) to RUBY by Paul Carvalho
#
# This program is free software and is distributed under the same terms as the Ruby GPL.
# See LICENSE.txt in the 'doc' folder for more information.
#
# Last Updated: 21 December 2007
#------------------------------------------------------------------------------------------------------------ #

(( ARGV.empty? ) or ( ARGV[0].to_i.zero? )) ? number = 1 : number = ARGV[0].to_i

### METHODS ###

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

begin
  f_DAYBREAKS = File.open( "../reports/breakdowns-day.txt" )
rescue
  puts "Can't find 'breakdowns-day.txt' file."
  exit
end
f_DAYBREAKS.gets     # (Discard the heading row)

puts "\nThese are the last #{number} days of test session progress"
puts Time.now.strftime("as of %m/%d/%y at %I:%M%p:").downcase

number.times do
  break if f_DAYBREAKS.eof?
  #($date,$total,$oncharter,$opportunity,$test,$bug,$prep,$pertester,$bugs,$issues)  << this is the original line, but there is *NO* 'per tester' field/value in this data file!
  ( date, total, oncharter, opportunity, test, bug, prep, bugs, issues ) = format_num( f_DAYBREAKS.gets.split('"').delete_if {|x| x.strip.empty? } )
  puts
  puts "        Date: #{date}"
  puts "       Total: #{total}"
  puts "  On Charter: #{oncharter}"
  puts " Opportunity: #{opportunity}"
  puts "        Test: #{test}"
  puts "         Bug: #{bug}"
  puts "       Setup: #{prep}"
#  puts "  Per Tester: #{pertester}"
  puts "        Bugs: #{bugs}"
  puts "      Issues: #{issues}"
end

puts

### END ###
