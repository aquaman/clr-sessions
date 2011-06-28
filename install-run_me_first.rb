#! /usr/bin/env ruby
#
# install-run_me_first.rb
#
# 1. delete all instances of .gitignore (needed in repository, but not in daily use)
# 2. a) in Windows, rewrite all text files to convert line endings from LF to CR
#       * files to skip: .PDF, .GIF, .RTF, .XLS
#       * delete any .SH files
#    b) in OS X, delete .BAT files and check the file permissions
# 3. Update SBTM.YML
#
# Last Updated:: 28 June 2011
#

puts
puts 'Cleaning up the files for first-time use...'
puts


# Collect the file and folder names:

filez = Dir[ '**/*' ]

folderz = ['.']
filez.each {|filename| folderz << filename  if ( File.basename( filename ) !~ /\./ ) }
filez.delete_if {|folder| File.basename( folder ) !~ /\./ }


## 1) delete all instances of .gitignore:

folderz.each do | folder_name |
  if Dir.entries( folder_name ).include? '.gitignore'
    File.delete( folder_name + '/.gitignore')
  end
end


## 2) some file maintenance depending on the Operating System:

if RUBY_PLATFORM =~ /mswin|windows|cygwin|mingw32/i

  # in Windows: rewrite text files, delete unix .SH scripts

  filez.delete_if {|filename| filename !~ /\.rb|\.txt|\.bat|\.sh|\.ini|\.yml|\.tpl|\.htm|\.ses|\.drd/i }

  def rewrite( filename )
    timez = []
    timez << File.ctime( filename ) 
    timez << File.mtime( filename ) 
    
    contentz = IO.readlines( filename )
    f = File.new( filename, 'w' )
    contentz.each {|line| f.puts line }
    f.close
    
    File.utime( timez.first, timez.last, filename )
  end

  filez.each do |file|
    
    if file.include? '.sh'
      File.delete( file ) 
      next
    end
    
    rewrite file

  end

else

  # in OS X or Unix: check the file permissions, delete Windows .BAT scripts

  filez.each do |file|
    
    if file.include? '.bat'
      File.delete( file ) 
      next
    end
    
    if file =~ /\.rb|\.sh/
      File.chmod( 0755, file )
    else
      File.chmod( 0644, file )
    end
    
  end

end


## 3) Update SBTM.YML:

puts '*' * 40
puts "\n Update the SBTM.YML configuration file\n\n"
puts '*' * 40
puts

# Find the 'config' folder & file..
config_file = ''
filez.each { |file| config_file = file if ( file =~ /sbtm\.yml/ and file !~ /doc/ ) }

if config_file.empty? or ! File.exist?( config_file )

  puts 'Could not find the "config/sbtm.yml" file to update.'
  puts 'Please be sure to update this file before you begin.'

else

  puts 'Updating : ' + config_file

  # Ask for name & initials
  full_name = ''
  initials = ''
  name_valid = false
  initials_valid = false

  while ! name_valid
    print "\n1) Enter your full name : "
    full_name = $stdin.gets.strip
    puts
    
    if full_name.empty? or full_name.length > 100
      puts '> Please enter the name you will use in your session sheets.'
      puts '> Please enter a name less than 100 characters.' if full_name.length > 100
    else
      name_valid = true
      full_name =~ /^(\S+)\s*/
      puts "Thanks, #{$1}!\n\n"
    end
    
    puts
  end

  while ! initials_valid
    print "2) Enter your initials  : "
    initials = $stdin.gets.strip
    inits = initials.length
    puts
    
    if initials.empty? or inits < 2 or inits > 3
      puts '> Your initials are used to create the session sheet file names.'
      puts '> Please enter 2 or 3 initials to uniquely identify your work.'
    else
      initials_valid = true
      puts 'Terrific!'
    end
    puts
  end

  # write info to SBTM.YML
  puts 'Adding your information to the configuration file ...'

  config_info = IO.readlines( config_file )
  f = File.new( config_file, 'w' )
  
  config_info.each do|line|
    if line =~ /full name:/
      line =~ /(\s+full name:\s+)(.*)/
      f.puts $1.chomp + full_name
      
    elsif line =~ /initials:/
      line =~ /(\s+initials:\s+)(.*)/
      f.puts $1.chomp + initials
      
    else
      f.puts line
    end
  end
  
  f.close
  
end

puts
puts 'Please check the "scan_options" to make sure they match your needs.'

puts "\n>> Setup complete.\n\n"
