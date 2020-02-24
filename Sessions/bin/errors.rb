#! /usr/bin/env ruby
# =========================================================================================================== #
# errors.rb
# Command Line Options : 1 Required - filename (see ERRORS.BAT)
# Purpose: to produce a list of error messages used in the given input file (e.g. SCAN.RB)
# ----------------------------------------------------------------------------------------------------------- #
# Ported from the original PERL script (dated 29-May-2000) to RUBY by Paul Carvalho
# Last Updated: 01 May 2007
# =========================================================================================================== #

if ( ARGV[0].nil? or ( ! File.exist?( ARGV[0] ) ) )
	puts "Specify the location of the [scan.*] file to scan for 'error' messages."
	exit
end

error_list = []
while gets
	error_list << $1 if $_ =~ /.+?error\(\s*\"(.+?)\"\s*\)/
end

f_ERRORS = File.new("errors.txt", "w")
error_list.sort.each {|x| f_ERRORS.puts x }
f_ERRORS.close
