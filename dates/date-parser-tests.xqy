import module namespace dates = "http://xqdev.com/dateparser" at "/lib/date-parser.xqy"

xdmp:set-response-content-type("text/html; charset=utf-8"),
<div id="content">

<h1>Testing</h1>

<p>
"last foo" = { empty(dates:parseDate("last foo")) }<br />
"2007/blah" = { empty(dates:parseDate("2007/blah")) }<br />
<br/>
"0" = { dates:parseDate("0")/value = xs:date("1900-01-01") }<br />
"9" = { dates:parseDate("9")/value = xs:date("2009-01-01") }<br />
"02" = { dates:parseDate("02")/value = xs:date("2002-01-01") }<br />
"09" = { dates:parseDate("09")/value = xs:date("2009-01-01") }<br />
"55" = { dates:parseDate("55")/value = xs:date("1955-01-01") }<br />
"99" = { dates:parseDate("99")/value = xs:date("1999-01-01") }<br />
"411" = { empty(dates:parseDate("411")) }<br />
"999" = { empty(dates:parseDate("999")) }<br />
"1953" = { dates:parseDate("1953")/value = xs:date("1953-01-01") }<br />
"2008" = { dates:parseDate("2008")/value = xs:date("2008-01-01") }<br />
"9999" = { dates:parseDate("9999")/value = xs:date("9999-01-01") }<br />

"0000" = { dates:parseDate("0000")/value = xs:date("1900-01-01") }<br />
"00000" = { dates:parseDate("00000")/value = xs:date("1900-01-01") }<br />
"00001" = { dates:parseDate("00001")/value = xs:date("1900-01-01") }<br />
"00009" = { dates:parseDate("00009")/value = xs:date("1900-09-01") }<br />
"000010" = { dates:parseDate("000010")/value = xs:date("1900-10-01") }<br />
"000013" = { empty(dates:parseDate("000013")) }<br />
"000099" = { empty(dates:parseDate("000099")) }<br />

"2005" = { dates:parseDate("2005")/value = xs:date("2005-01-01") }<br />
"20050" = { dates:parseDate("20050")/value = xs:date("2005-01-01") }<br />
"20051" = { dates:parseDate("20051")/value = xs:date("2005-01-01") }<br />
"20059" = { dates:parseDate("20059")/value = xs:date("2005-09-01") }<br />
"200510" = { dates:parseDate("200510")/value = xs:date("2005-10-01") }<br />
"200513" = { empty(dates:parseDate("200513")) }<br />
"200599" = { empty(dates:parseDate("200599")) }<br />

"200500" = { dates:parseDate("200500")/value = xs:date("2005-01-01") }<br />
"2005060" = { dates:parseDate("2005060")/value = xs:date("2005-06-01") }<br />
"2005067" = { dates:parseDate("2005067")/value = xs:date("2005-06-07") }<br />
"20050609" = { dates:parseDate("20050609")/value = xs:date("2005-06-09") }<br />
"20051231" = { dates:parseDate("20051231")/value = xs:date("2005-12-31") }<br />
"20050699" = { empty(dates:parseDate("20050699")) }<br />
"20051332" = { empty(dates:parseDate("20051332")) }<br />
"20059999" = { empty(dates:parseDate("20059999")) }<br />
"99999999" = { empty(dates:parseDate("99999999")) }<br />

"999999991" = { empty(dates:parseDate("999999991")) }<br />
"99999999abc" = { empty(dates:parseDate("99999999abc")) }<br />
"abc99999999" = { empty(dates:parseDate("abc99999999")) }<br />
</p>
<p>
"2005/10" = { dates:parseDate("2005/10")/value = xs:date("2005-10-01") }<br />
"2005/10/2" = { dates:parseDate("2005/10/2")/value = xs:date("2005-10-02") }<br />
"2005/10/03" = { dates:parseDate("2005/10/03")/value = xs:date("2005-10-03") }<br />

"07/10/79" = { dates:parseDate("07/10/79")/value = xs:date("1979-07-10") }<br />
"07/10/1979" = { dates:parseDate("07/10/79")/value = xs:date("1979-07-10") }<br />
"7/9/1979" = { dates:parseDate("7/9/79")/value = xs:date("1979-07-09") }<br />
<br/>
"2005-10" = { dates:parseDate("2005-10")/value = xs:date("2005-10-01") }<br />
"2005-10-2" = { dates:parseDate("2005-10-2")/value = xs:date("2005-10-02") }<br />
"2005-10-03" = { dates:parseDate("2005-10-03")/value = xs:date("2005-10-03") }<br />

"07-10-79" = { dates:parseDate("07-10-79")/value = xs:date("1979-07-10") }<br />
"07-10-1979" = { dates:parseDate("07-10-79")/value = xs:date("1979-07-10") }<br />
"7-9-1979" = { dates:parseDate("7-9-79")/value = xs:date("1979-07-09") }<br />
<br/>
"2005-dec-13" = { dates:parseDate("2005-dec-13")/value = xs:date("2005-12-13") }<br />
<br/>
"jan-10-79" = { dates:parseDate("jan-10-79")/value = xs:date("1979-01-10") }<br />
"feb-10-79" = { dates:parseDate("feb-10-79")/value = xs:date("1979-02-10") }<br />
"mar-10-79" = { dates:parseDate("mar-10-79")/value = xs:date("1979-03-10") }<br />
"apr-10-79" = { dates:parseDate("apr-10-79")/value = xs:date("1979-04-10") }<br />
"may-10-79" = { dates:parseDate("may-10-79")/value = xs:date("1979-05-10") }<br />
"jun-10-79" = { dates:parseDate("jun-10-79")/value = xs:date("1979-06-10") }<br />
"jul-10-79" = { dates:parseDate("jul-10-79")/value = xs:date("1979-07-10") }<br />
"aug-10-79" = { dates:parseDate("aug-10-79")/value = xs:date("1979-08-10") }<br />
"sep-10-79" = { dates:parseDate("sep-10-79")/value = xs:date("1979-09-10") }<br />
"oct-10-79" = { dates:parseDate("oct-10-79")/value = xs:date("1979-10-10") }<br />
"nov-10-79" = { dates:parseDate("nov-10-79")/value = xs:date("1979-11-10") }<br />
"dec-10-79" = { dates:parseDate("dec-10-79")/value = xs:date("1979-12-10") }<br />
<br/>
"January-10-79" = { dates:parseDate("January-10-79")/value = xs:date("1979-01-10") }<br />
"February-10-79" = { dates:parseDate("February-10-79")/value = xs:date("1979-02-10") }<br />
"March-10-79" = { dates:parseDate("March-10-79")/value = xs:date("1979-03-10") }<br />
"April-10-79" = { dates:parseDate("April-10-79")/value = xs:date("1979-04-10") }<br />
"May-10-79" = { dates:parseDate("May-10-79")/value = xs:date("1979-05-10") }<br />
"June-10-79" = { dates:parseDate("June-10-79")/value = xs:date("1979-06-10") }<br />
"July-10-79" = { dates:parseDate("July-10-79")/value = xs:date("1979-07-10") }<br />
"August-10-79" = { dates:parseDate("August-10-79")/value = xs:date("1979-08-10") }<br />
"September-10-79" = { dates:parseDate("September-10-79")/value = xs:date("1979-09-10") }<br />
"October-10-79" = { dates:parseDate("October-10-79")/value = xs:date("1979-10-10") }<br />
"November-10-79" = { dates:parseDate("November-10-79")/value = xs:date("1979-11-10") }<br />
"December-10-79" = { dates:parseDate("December-10-79")/value = xs:date("1979-12-10") }<br />
<br/>
"enero-10-79" = { dates:parseDate("enero-10-79")/value = xs:date("1979-01-10") }<br />
"febrero-10-79" = { dates:parseDate("febrero-10-79")/value = xs:date("1979-02-10") }<br />
"marzo-10-79" = { dates:parseDate("marzo-10-79")/value = xs:date("1979-03-10") }<br />
"abril-10-79" = { dates:parseDate("abril-10-79")/value = xs:date("1979-04-10") }<br />
"mayo-10-79" = { dates:parseDate("mayo-10-79")/value = xs:date("1979-05-10") }<br />
"junio-10-79" = { dates:parseDate("junio-10-79")/value = xs:date("1979-06-10") }<br />
"julio-10-79" = { dates:parseDate("julio-10-79")/value = xs:date("1979-07-10") }<br />
"agosto-10-79" = { dates:parseDate("agosto-10-79")/value = xs:date("1979-08-10") }<br />
"septiembre-10-79" = { dates:parseDate("septiembre-10-79")/value = xs:date("1979-09-10") }<br />
"octubre-10-79" = { dates:parseDate("octubre-10-79")/value = xs:date("1979-10-10") }<br />
"noviembre-10-79" = { dates:parseDate("noviembre-10-79")/value = xs:date("1979-11-10") }<br />
"diciembre-10-79" = { dates:parseDate("diciembre-10-79")/value = xs:date("1979-12-10") }<br />
<br/>
"janvier-10-79" = { dates:parseDate("janvier-10-79")/value = xs:date("1979-01-10") }<br />
"fevrier-10-79" = { dates:parseDate("fevrier-10-79")/value = xs:date("1979-02-10") }<br />
"mars-10-79" = { dates:parseDate("mars-10-79")/value = xs:date("1979-03-10") }<br />
"avril-10-79" = { dates:parseDate("avril-10-79")/value = xs:date("1979-04-10") }<br />
"mai-10-79" = { dates:parseDate("mai-10-79")/value = xs:date("1979-05-10") }<br />
"juin-10-79" = { dates:parseDate("juin-10-79")/value = xs:date("1979-06-10") }<br />
"juillet-10-79" = { dates:parseDate("juillet-10-79")/value = xs:date("1979-07-10") }<br />
"aout-10-79" = { dates:parseDate("aout-10-79")/value = xs:date("1979-08-10") }<br />
"septembre-10-79" = { dates:parseDate("septembre-10-79")/value = xs:date("1979-09-10") }<br />
"octobre-10-79" = { dates:parseDate("octobre-10-79")/value = xs:date("1979-10-10") }<br />
"novembre-10-79" = { dates:parseDate("novembre-10-79")/value = xs:date("1979-11-10") }<br />
"decembre-10-79" = { dates:parseDate("decembre-10-79")/value = xs:date("1979-12-10") }<br />
<br/>
"januar-10-79" = { dates:parseDate("januar-10-79")/value = xs:date("1979-01-10") }<br />
"februar-10-79" = { dates:parseDate("februar-10-79")/value = xs:date("1979-02-10") }<br />
"marz-10-79" = { dates:parseDate("marz-10-79")/value = xs:date("1979-03-10") }<br />
"april-10-79" = { dates:parseDate("april-10-79")/value = xs:date("1979-04-10") }<br />
"mai-10-79" = { dates:parseDate("mai-10-79")/value = xs:date("1979-05-10") }<br />
"juni-10-79" = { dates:parseDate("juni-10-79")/value = xs:date("1979-06-10") }<br />
"juli-10-79" = { dates:parseDate("juli-10-79")/value = xs:date("1979-07-10") }<br />
"august-10-79" = { dates:parseDate("august-10-79")/value = xs:date("1979-08-10") }<br />
"september-10-79" = { dates:parseDate("september-10-79")/value = xs:date("1979-09-10") }<br />
"oktober-10-79" = { dates:parseDate("oktober-10-79")/value = xs:date("1979-10-10") }<br />
"november-10-79" = { dates:parseDate("november-10-79")/value = xs:date("1979-11-10") }<br />
"dezember-10-79" = { dates:parseDate("dezember-10-79")/value = xs:date("1979-12-10") }<br />
<br/>
"gennaio-10-79" = { dates:parseDate("gennaio-10-79")/value = xs:date("1979-01-10") }<br />
"febbraio-10-79" = { dates:parseDate("febbraio-10-79")/value = xs:date("1979-02-10") }<br />
"marzo-10-79" = { dates:parseDate("marzo-10-79")/value = xs:date("1979-03-10") }<br />
"aprile-10-79" = { dates:parseDate("aprile-10-79")/value = xs:date("1979-04-10") }<br />
"maggio-10-79" = { dates:parseDate("maggio-10-79")/value = xs:date("1979-05-10") }<br />
"giugno-10-79" = { dates:parseDate("giugno-10-79")/value = xs:date("1979-06-10") }<br />
"luglio-10-79" = { dates:parseDate("luglio-10-79")/value = xs:date("1979-07-10") }<br />
"agosto-10-79" = { dates:parseDate("agosto-10-79")/value = xs:date("1979-08-10") }<br />
"settembre-10-79" = { dates:parseDate("settembre-10-79")/value = xs:date("1979-09-10") }<br />
"ottobre-10-79" = { dates:parseDate("ottobre-10-79")/value = xs:date("1979-10-10") }<br />
"novembre-10-79" = { dates:parseDate("novembre-10-79")/value = xs:date("1979-11-10") }<br />
"dicembre-10-79" = { dates:parseDate("dicembre-10-79")/value = xs:date("1979-12-10") }<br />
<br/>
"August 10, 2008" = { dates:parseDate("August 10, 2008")/value = xs:date("2008-08-10") }<br />
"December 1st, 2007" = { dates:parseDate("December 1st, 2007")/value = xs:date("2007-12-01") }<br />
"December 2nd, 2007" = { dates:parseDate("December 2nd, 2007")/value = xs:date("2007-12-02") }<br />
"December 3rd, 2007" = { dates:parseDate("December 3rd, 2007")/value = xs:date("2007-12-03") }<br />
"December 4th, 2007" = { dates:parseDate("December 4th, 2007")/value = xs:date("2007-12-04") }<br />
"December 20, 2007" = { dates:parseDate("December 20, 2007")/value = xs:date("2007-12-20") }<br />
"December 2006" = { dates:parseDate("December 2006")/value = xs:date("2006-12-01") }<br />
<br/>
"today" = { dates:parseDate("today")/value = current-date() }<br />
"yesterday" = { dates:parseDate("yesterday")/value = current-date() - xdt:dayTimeDuration("P1D") }<br />
"t2d" = { dates:parseDate("t2d")/value = current-date() - xdt:dayTimeDuration("P2D") }<br />
"last week" = { dates:parseDate("last week") }<br />
</p>
</div>
