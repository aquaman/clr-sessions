#
# install_win.rb - Run Me First on Windows!!!
#
# 1. check to make sure this is a Windows system. If not, stop
# 2. collect list of files in sub-directories
# 3. delete all instances of .gitignore
# 4. rewrite all files that have had the line endings set to LF
#    a) be sure to 'touch' the file and set the correct file date info.
#    b) files to rewrite include EVERYTHING, except: .PDF, .GIF, .RTF, .XLS
# 5. Update SBTM.YML
#
# Last Updated:: 24 June 2011
#

## 1) Check to make sure this is a Windows operating system:

if RUBY_PLATFORM !~ /mswin|windows|cygwin|mingw32/i
  puts 'This script is meant for users of the MS Windows operating system only.'
  puts 'Nothing to do.'
  exit
end

puts
puts 'Cleaning up the files for Windows use...'
puts


## 2) Collect the file and folder names:

filez = Dir[ '**/*' ]


## 3) delete all instances of .gitignore:

folderz = ['.']
filez.each {|filename| folderz << filename  if ( File.basename( filename ) !~ /\./ ) }

folderz.each do | folder_name |
  if Dir.entries( folder_name ).include? '.gitignore'
    File.delete( folder_name + '/.gitignore')
  end
end


## 4) rewrite all text files to change the line endings from LF to CR:

filez.delete_if {|filename| filename !~ /\.rb|\.txt|\.bat|\.ini|\.yml|\.tpl|\.htm|\.ses|\.drd/i }

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

filez.each {|file| rewrite file }


## 5) Update SBTM.YML:

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

puts "\n>> Setup complete."
