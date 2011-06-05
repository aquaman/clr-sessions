<html>

<head>
<meta http-equiv="Content-Language" content="en-us">
<meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
<title>Test Coverage Totals</title>
</head>

<body>

<h1><b><font face="Arial">Test Coverage Totals</font></b></h1>
<p><a href="status.htm"><b>Return to Summary page</b></a></p>
<pre>
Report current as of: 02/01/01 02:00pm
</pre>
<p>This report shows how test sessions map to coverage areas. All numbers except
Bugs and Issues represent normal sessions. A normal session is about 90 minutes
of uninterrupted test time by a single tester. If the Total column reports &quot;15&quot; for a
particular area, it means that the specified area was mentioned on session
reports that totaled to a duration equivalent to 15 normal sessions worth of
testing. A coverage area is entered in the #AREAS section of a test session
report only if the test lead verifies that a substantial part of the session
covered that area. Thus, this is a rough, but meaningful indication of test
coverage from a tester's perspective.</p>
<table border="1" width="99%">
  <tr bgcolor="#C0C0C0">
table header goes here
    <th width="7%"><font face="Arial"><a href="c_by_bugs.htm">BUGS</a></font></th>
    <th width="7%"><font face="Arial"><a href="c_by_issues.htm">ISSUES</a></font></th>
    <td width="48%"><b><font face="Arial"><a href="c_by_area.htm">AREA</a></font></b></td>
  </tr>
table data goes here
</table>
<h2><font face="Arial">Column Definitions</font></h2>
<h3><a name="total"></a><font face="Arial">TOTAL = <i>total amount of associated
session work</i></font></h3>
<p>The total amount of session work, expressed in normal sessions, that is
associated with a coverage area. If the Total column reports &quot;15&quot; for
a particular area, it means that the specified area was mentioned on session
reports that totaled to a duration equivalent to 15 normal sessions worth of
testing. Note that you cannot add totals from different areas, since session
totals from different areas may well have sessions in common. </p>
<h3><a name="chtr"></a><font face="Arial">CHTR = <i>total amount of on-charter
work</i></font></h3>
<p>The total amount of session work that was within the charter of each session.
This value plus the Opportunity value should equal the total amount of session
work associated with the corresponding coverage area. CHTR + OPP = TOTAL</p>
<h3><a name="opp"></a><font face="Arial">OPP =<i> total amount of off-charter
work</i></font></h3>
<p>The amount of session work that was <i>not</i> within the charter of each
session. This work may or may not have been associated with the corresponding
coverage area. All we know is that the work was off the subject of the specific
charter. A disproportionately high ratio of off-charter to on-charter work in a
particular coverage area may represent that another test area related to this
one may be distracting the testers. CHTR + OPP = TOTAL</p>
<h3><a name="test"></a><font face="Arial">TEST = <i>amount of on-charter test
design and execution</i></font></h3>
<p>The amount of on-charter work that was devoted to searching for bugs. The
higher this value, the more time was spent by testers productively testing. Note
that some product areas are much more testable than others, so 10 sessions of
testing in one area may not have the same value as 10 sessions in another. TEST
+ BUG + SETUP = CHTR.</p>
<h3><a name="bug"></a><font face="Arial">BUG <i>= amount of on-charter bug
investigation and reporting that interrupted testing</i></font></h3>
<p>The amount of on-charter work that was devoted to investigating and reporting
bugs. This work is only reported if it interrupts bug searching. Thus, the fewer
problems there are, or the easier they are to investigate, the lower this value
will be, and the more testing will get done. TEST + BUG + SETUP = CHTR.</p>
<h3><a name="setup"></a><font face="Arial">SETUP = <i>amount of session setup
work that interrupted testing</i></font></h3>
<p>The amount of on-charter work that was devoted to anything other than bug
searching or bug investigation and reporting. This work is only reported if it
interrupts bug searching. Typically this category includes gathering information
for testing, setting up equipment, or filling out the session reports. Thus, the
more organized the test process is, the lower this value will be, and the more
testing will get done. Chronically high setup values probably indicate that the
test project is still getting up to speed. TEST + BUG + SETUP = CHTR.</p>
<h3><a name="bugs"></a><font face="Arial">BUGS = <i>total number of bugs found
in sessions associated with this coverage area</i></font></h3>
<p>The total number of bugs reported to the test lead that are associated with
this coverage area. Not every bug reported to the test lead will be proper to
report in the bug tracking system. A high ratio of BUGS to TEST generally
indicates either a weak area of the product, or an area that confuses the testers.</p>
<h3><a name="issues"></a><font face="Arial">ISSUES = <i>total number of issues
found in sessions associated with this coverage area</i></font></h3>
<p>The total number of issues reported in sessions associated with the coverage
area. A high ratio of ISSUES to CHTR generally indicates a testability problem
in that area.</p>
<h3><a name="area"></a><font face="Arial">AREA = <i>coverage area</i></font></h3>
<p>The coverage area to which the metrics apply. What we call &quot;coverage
areas&quot; goes beyond areas of the product itself. Types of testing, build
numbers, and platforms are also reported. However, mostly the areas correspond
to functional, structural or data elements of the product. These areas are
predefined and controlled by the test lead. We selected these specific areas to
allow reasonably granular reporting while not getting so granular that the
accuracy suffers.</p>
<p>&nbsp;</p>

</body>

</html>
