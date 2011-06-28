#!/bin/bash
#
# scan-approved-then-run-report.bat
#

#
# This is a sample Windows script that you can use to automate several
# actions at once.  For example, this script does the following:
# * scan files and display results
# * generate HTML report and display it in web browser
#

# Check the file integrity of the approved sheets. Create summary files.

../../../bin/scan2.rb config approved

open scan.log


# Generate HTML reports

../../../bin/report2.rb config

open reports/status.htm
