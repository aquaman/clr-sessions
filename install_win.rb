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
# Last Updated:: 22 June 2011
#

## 1) Check to make sure this is a Windows operating system:

# puts ENV['OS'] << returns OS in windows, but blank/nil in Linux. what about OS X? Test this!

if RUBY_PLATFORM !~ /mswin|windows|cygwin|mingw32/i
  puts 'This script is meant for users of the MS Windows operating system only.'
  puts 'Nothing to do.'
  exit
end


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


## 4) rewrite all files that have had the line endings set to LF:

filez.delete_if {|filename| filename !~ /\.rb|\.txt|\.bat|\.ini|\.yml|\.tpl|\.htm|\.ses|\.drd/i }
filez.delete( File.basename($0) )   # (let's not overwrite the script that is running!)

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

# Ask for name
# Ask for initials
# write info to SBTM.YML

puts 'Done!'
