# CLR-SESSIONS
## Command-Line Ruby Session-Based Testing Framework

Current Build status: 
[![Build Status](https://api.travis-ci.org/aquaman/clr-sessions.png)](https://travis-ci.org/aquaman/clr-sessions)<br/>
<i>(current build failures expected while I set up the CI server... please stand by. The ruby scripts still work with older versions of ruby.)</i>

CLR-Sessions is a text file-based framework for managing Exploratory Testing. The testing notes are saved as text files so you can use your favourite text editor. The supporting ruby scripts create the basic file templates, do basic error-checking, and generate some helpful reports. Essentially, this is a flat-file database program. It is handy for portability across systems, but not sophisticated enough for complex multi-project scenarios.

To understand the context for this framework, search for information on Session-Based Test Management or SBTM. If you don't know where to start, this page has some helpful info and links: http://staqs.com/docs/sbtm

History: I ported this framework from Perl to Ruby back in 2007. I then extended it with bug fixes and additional features until about 2012. I used this as a primary test management framework for commercial IT development projects for many years. Despite the limitations, it was still the best tool I had for managing exploratory testing efforts (along with a few more tools).

Currently, this framework only supports Ruby 1.8.6, 1.8.7 and 1.9.2. Work is underway now (Fall 2014) to resurrect and complete this tool. Additional helpers are welcome.

Please read the INSTALL.txt and work through the examples in the "docs" folder. Please leave me feedback or add Issues to this repo to help me prioritise fixes in the coming weeks.

Thanks. Happy Testing!

Cheers!
