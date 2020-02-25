#! /usr/bin/env ruby
# =========================================================================================================== #
# errors.rb
# Command Line Options : 1 Required - filename (see ERRORS.BAT)
# Purpose: to produce a list of error messages used in the given input file (e.g. SCAN.RB)
# ----------------------------------------------------------------------------------------------------------- #
# Ported from the original PERL script (dated 29-May-2000) to RUBY by Paul Carvalho
#
# This program is free software and is distributed under the same terms as the Ruby GPL.
# See LICENSE.txt in the 'doc' folder for more information.
#
# Last Updated: 24 February 2020
# =========================================================================================================== #

if ( ARGV[0].nil? or ( ! File.exist?( ARGV[0] ) ) )
  puts "Specify the location of the [scan.*] file to scan for 'error' messages."
  exit
end

error_list = []
while gets
  error_msg_found = false
  error_msg = ''
  if $_ =~ /.+?error\(\s*[\"|\'](.+?)[\"|\']\s*\)/
    # Single-line error message
    error_msg = $1
    error_msg_found = true
  elsif $_ =~ /.+?error\(\s*[\"|\'](.+?)[\"|\']\s*\+/
    # Multi-line error message
    error_msg = $1
    gets =~ /\s*[\"|\'](.+?)[\"|\']\s*\)/
    error_msg << $1
    error_msg_found = true
  end
  error_list << error_msg if error_msg_found
end

f_ERRORS = File.new("errors.txt", "w")
error_list.sort.each {|x| f_ERRORS.puts x }
f_ERRORS.close
