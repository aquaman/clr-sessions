# CLR-SESSIONS
## Command-Line Ruby Session-Based Testing Framework

CLR-Sessions is a command-line test management framework for managing Exploratory Testing. It is more than a prototype and less than a fully robust system. Using this tool set requires understanding Session-Based Test Management or SBTM. If you don't know where to start, this page has some helpful info and links: http://staqs.com/docs/sbtm

Overview: Save your exploratory testing notes in plain text files using a template for organising your thoughts into specific sections. The supporting ruby scripts create the basic file templates, do basic error-checking, and generate some helpful reports. Essentially, this is a flat-file database program. It is handy for portability across systems, and barely sophisticated enough to handle multi-project scenarios (with some folder-tweaking and batch file modifications).

History: I ported this framework from the original Perl scripts to Ruby in 2007. I fixed several bugs from the original Perl scripts and then extended them with more error-checking and features until about 2012. I used this as a primary test management framework for commercial IT development projects for many years across many organisations. Despite the limitations, it was still the best tool I had for managing exploratory testing efforts (along with a few more tools). In 2020, I revisited the toolset to update it to work with the latest versions of Ruby (2.6 and 2.7), and I plan to add a series of automated tests as an exercise for the BDD classes I teach agile development teams.

## Installation
Please read the INSTALL.txt for instructions and examples. In a nutshell:

1. Install Ruby
1. Download a Zip copy of this project to your local hard drive
1. Run the Ruby install script (install-run_me_first.rb) to configure it for first-time use
1. Start creating new sessions
1. Remember that all \*.SES files are text files. Associate the \*.SES file extension to your favourite text editor.

Demo: If you want to start with a demo of the features, do the following:
1. Navigate to 'Sessions/doc/examples/DecideRight'
1. Run the script 'scan-approved-example-then-run-report..' (_.bat or .sh_ depending upon your OS)
1. An HTML summary report should open in your browser. Review it and the other files generated in the 'reports' folder

Please leave me feedback or add Issues to this repo to help me prioritise fixes in the coming weeks.

Thanks. Happy Testing!

Cheers!
