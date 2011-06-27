#!/bin/bash
#
# scan-approved-then-run-report.bat
#

# Check the file integrity of the approved sheets. Create summary files.
bin/scan2.rb config approved

# modify the next line to open the log file in your favourite editor:
cat scan.log


# Generate HTML reports
bin/report2.rb config

# launch the following in your preferred web browser:
open reports/status.htm
