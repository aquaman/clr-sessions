<html>

<head>
  <meta http-equiv="Content-Language" content="en-us">
  <meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
  <title>Completed Session Sheets</title>
</head>

<body>

<h1><b><font face="Arial">Completed Session Sheets</font></b></h1>

<p><a href="status.htm"><b>Return to Summary page</b></a></p>
<pre>
Report current as of: 02/01/01 02:00pm
</pre>
<p>This report is a list of test sessions along with their vital statistics. All
  numbers except Bugs, Issues, and Testers represent normal sessions. A normal
  session is about 90 minutes of uninterrupted test time by a single tester. An
  actual session may be worth more or less than a normal session depending on the
  duration of the session and the number of testers involved with it.</p>

<p>Each session row is linked to the full session report.</p>
<table border="1" width="99%">
  <tr bgcolor="#C0C0C0">
    <th><font face="Arial"><a href="sess_by_ses.htm">SESSION</a></font></th>
    <th><font face="Arial"><a href="sess_by_datetime.htm">DATE</a></font></th>
    <th><font face="Arial"><a href="sess_by_time.htm">TIME</a></font></th>
table header goes here
    <th><font face="Arial"><a href="sess_by_num_bugs.htm"># BUGS</a></font></th>
    <th><font face="Arial"><a href="sess_by_num_issues.htm"># ISSUES</a></font></th>
    <th><font face="Arial"><a href="sess_by_num_testers.htm"># TESTERS</a></font></th>
  </tr>
table data goes here
</table>
<h2><font face="Arial">Column Definitions</font></h2>

<dl>
  <dt>
  <h3><a name="session"></a><font face="Arial">SESSION = <i>the title of the
    session report</i></font></h3></dt>

  <dd>This value is linked to the actual session report, which you can view for more
    information about the session.
  </dd>

  <dt>
  <h3><a name="date"></a><font face="Arial">DATE = <i>the day the session
    started</i></font></h3></dt>

  <dd>&nbsp;</dd>

  <dt>
  <h3><a name="time"></a><font face="Arial">TIME = <i>the time the session
    started</i></font></h3></dt>

  <dd>&nbsp;</dd>

  <dt>
  <h3><a name="duration"></a><font face="Arial">DUR = <i>the approximate duration of
    the session</i></font></h3></dt>

  <dd>Duration is specified in terms of normal session units. Each session is worth
    about 90 minutes of uninterrupted tester attention.
  </dd>

  <dt>
  <h3><a name="charter"></a><font face="Arial">CHTR = <i>total amount of on-charter
    work</i></font></h3></dt>

  <dd>The total amount of session work that was within the charter of each session.
    This value plus the Opportunity value should equal the total amount of session
    work associated with the corresponding coverage area. CHTR + OPP = TOTAL
  </dd>

  <dt>
  <h3><a name="opp"></a><font face="Arial">OPP = <i>total amount of off-charter
    work</i></font></h3></dt>

  <dd>The amount of session work that was <i>not</i> within the charter of each
    session. The TBS breakdown for opportunity testing is not reported. All we know
    is that the work was off the subject of the specific charter. CHTR + OPP = TOTAL
  </dd>

  <dt>
  <h3><a name="test_time"></a><font face="Arial">% TEST = <i>amount of on-charter test
    design and execution</i></font></h3></dt>

  <dd>The amount of on-charter work that was devoted to searching for bugs. The
    higher this value, the more time was spent by testers productively testing.
    (% TEST) + (% BUG) + (% SETUP) = CHTR.
  </dd>

  <dt>
  <h3><a name="bug_time"></a><font face="Arial">% BUG = <i>amount of on-charter bug
    investigation and reporting that interrupted testing</i></font></h3></dt>

  <dd>The amount of on-charter work that was devoted to investigating and reporting
    bugs. This work is only reported if it interrupts bug searching. Thus, the fewer
    problems there are, or the easier they are to investigate, the lower this value
    will be, and the more testing will get done. (% TEST) + (% BUG) + (% SETUP) = CHTR.
  </dd>

  <dt>
  <h3><a name="setup_time"></a><font face="Arial">% SETUP = <i>amount of session setup
    work that interrupted testing</i></font></h3></dt>

  <dd>The amount of on-charter work that was devoted to anything other than bug
    searching or bug investigation and reporting. This work is only reported if it
    interrupts bug searching. Typically, this category includes gathering
    information for testing, setting up equipment, or filling out the session
    reports. Thus, the more organized the test process is, the lower this value will
    be, and the more testing will get done. Chronically high setup values probably
    indicate that the test project is still getting up to speed.
    (% TEST) + (% BUG) + (% SETUP) = CHTR.
  </dd>

  <dt>
  <h3><a name="num_bugs"></a><font face="Arial"># BUGS = <i>total number of bugs found
    in the session</i></font></h3></dt>

  <dd>The total number of bugs reported to the test lead during the session. Not every bug
    reported to the test lead will be proper to report in the bug tracking system.
  </dd>

  <dt>
  <h3><a name="num_issues"></a><font face="Arial"># ISSUES = <i>total number of issues
    found in the session</i></font></h3></dt>

  <dd>The total number of issues reported in the session. Issues can be problems
    with the test process or questions about the product that are escalated to the test lead.
  </dd>

  <dt>
  <h3><a name="num_testers"></a><font face="Arial"># TESTERS = <i>number
    of testers on the session</i></font></h3></dt>

  <dd>The number of testers who were devoted to the session. A session with two
    testers counts as two sessions worth of work.
  </dd>
</dl>
<p>&nbsp;</p>

</body>

</html>
