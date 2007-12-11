(:~
 : Various Date String Parser
 :
 : Copyright 2007 Ryan Grimm
 :
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 :     http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :
 : @author Ryan Grimm (grimm@xqdev.com)
 : @version 0.1
 :
 :)

module "http://xqdev.com/dateparser"
declare namespace dates = "http://xqdev.com/dateparser"

default function namespace = "http://www.w3.org/2003/05/xpath-functions"


(:~
 : Parses various flavors of date strings and if successful returns the date
 : as a xs:dateTime value.  Please report all bugs (I know of some already)
 : and missing date formats to the author (there are many of these as well).
 :
 : @param $date the date string to parse
 :   Currently suppoted date formats include:
 :     30 Jun 2006 09:39:08 -0500
 :     Apr 16 13:49:06 2003 +0200
 :     Aug 04 11:44:58 EDT 2003
 :     4 Jan 98 0:41 EDT
 :     25-Oct-2004 17:06:46 -0500
 :     Mon, 23 Sep 0102 23:14:26 +0900
 :   For dates with time names (eg: EDT) we do our best to map these to a GMT offset. 
 :   The date doesn't need to be at the beginning of $date.  For example the string
 :   "Today is Aug 04 11:44:58 EDT 2003 hope it's a good one" will parse without issue.
 :   However, if there is more than one date in $date, only the first one is parsed. 
 :
 : @return if successful, the date cast as an xs:dateTime
 :)
define function dates:parse(
	$s as xs:string?
) as xs:dateTime?
{
	if(empty($s))
	then ()
	else
		let $i := lower-case(normalize-space($s))
		let $date := dates:_tokenParse($i)
		let $date := if(exists($date)) then $date else dates:_dashParse($i)
		return $date
}

define function dates:_tokenParse(
	$i as xs:string
) as xs:dateTime?
{
	(
	let $bits := tokenize($i, "[ ,]+")
	let $positions :=
		for $i at $pos in $bits
		where $i = ("jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec")
		return $pos
	for $pos in $positions
	let $date := dates:_tokParse1($bits, $pos)
	let $date := if(exists($date)) then $date else dates:_tokParse2($bits, $pos)
	let $date := if(exists($date)) then $date else dates:_tokParse3($bits, $pos)
	let $date := if(exists($date)) then $date else dates:_tokParse4($bits, $pos)
	return $date
	)[1]
}

define function dates:_tokParse1(
	$bits as xs:string*,
	$pos as xs:integer
) as xs:dateTime?
{
	(: 30 Jun 2006 09:39:08 -0500 :)
	let $year := dates:_processYear($bits[$pos + 1])
	let $month := dates:_processMonth($bits[$pos])
	let $day := dates:_processDay($bits[$pos - 1])
	let $zone := dates:_processZone($bits[$pos + 3]) (: optional time zone :)
	let $date := concat($year, "-", $month, "-", $day, "T", dates:_processTime($bits[$pos + 2]), $zone)
	where $date castable as xs:dateTime
	return xs:dateTime($date)
}

define function dates:_tokParse2(
	$bits as xs:string*,
	$pos as xs:integer
) as xs:dateTime?
{
	(: Apr 16 13:49:06 2003 +0200 :)
	let $year := dates:_processYear($bits[$pos + 3])
	let $month := dates:_processMonth($bits[$pos])
	let $day := dates:_processDay($bits[$pos + 1])
	let $zone := dates:_processZone($bits[$pos + 4]) (: optional time zone :)
	let $date := concat($year, "-", $month, "-", $day, "T", $bits[$pos + 2], $zone)
	where $date castable as xs:dateTime
	return xs:dateTime($date)
}

define function dates:_tokParse3(
	$bits as xs:string*,
	$pos as xs:integer
) as xs:dateTime?
{
	(: Aug 04 11:44:58 EDT 2003 :)
	let $year := dates:_processYear($bits[$pos + 4])
	let $month := dates:_processMonth($bits[$pos])
	let $day := dates:_processDay($bits[$pos + 1])
	let $zone := dates:_processZone($bits[$pos + 3])
	let $date := concat($year, "-", $month, "-", $day, "T", $bits[$pos + 2], $zone)
	where $date castable as xs:dateTime
	return xs:dateTime($date)
}

define function dates:_tokParse4(
	$bits as xs:string*,
	$pos as xs:integer
) as xs:dateTime?
{
	(: 4 Jan 98 0:41 EDT :)
	let $year := dates:_processYear($bits[$pos + 2])
	let $month := dates:_processMonth($bits[$pos + 1])
	let $day := dates:_processDay($bits[$pos])
	let $zone := dates:_processZone($bits[$pos + 4])
	let $date := concat($year, "-", $month, "-", $day, "T", dates:_processTime($bits[$pos + 3]), $zone)
	where $date castable as xs:dateTime
	return xs:dateTime($date)
}

define function dates:_dashParse(
	$i as xs:string
) as xs:dateTime?
{
	(: 25-oct-2004 17:06:46 -0500 :)
	let $raw := replace($i, ".*(0\d| \d|\d\d)-(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)", "$1 $2")
	let $bits := tokenize(normalize-space($raw), " ")
	let $dateBits := tokenize($bits[2], "-")
	let $year := dates:_processYear($dateBits[2])
	let $month := dates:_processMonth($dateBits[1])
	let $day := dates:_processDay($bits[1])
	let $zone := dates:_processZone($bits[4])
	let $date := concat($year, "-", $month, "-", $day, "T", dates:_processTime($bits[3]), $zone)
	where $date castable as xs:dateTime
	return xs:dateTime($date)
}

define function dates:_processYear(
	$year as xs:string?
) as xs:string?
{
	if($year castable as xs:integer and xs:integer($year) < 100)
	then
		if(xs:integer($year) > 70)
		then concat("19", string-pad("0", 2 - string-length($year)), $year)
		else concat("20", string-pad("0", 2 - string-length($year)), $year)
	else if($year castable as xs:integer and xs:integer($year) >= 100 and xs:integer($year) < 200)  (: 102 = 2002 in Java :)
	then
		xs:string(1900 + xs:integer($year))
	else $year
}

define function dates:_processMonth(
	$month as xs:string?
) as xs:string?
{
	let $months := ("jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec")
	for $i at $pos in $months
	where $i = $month
	return concat(string-pad("0", 2 - string-length(string($pos))), $pos)
}

define function dates:_processDay(
	$day as xs:string?
) as xs:string?
{
	concat(string-pad("0", 2 - string-length($day)), $day)
}

define function dates:_processTime(
	$time as xs:string?
) as xs:string
{
	let $bits := tokenize($time, ":")
	let $hours :=
		if(exists($bits[1]))
		then concat(string-pad("0", 2 - string-length($bits[1])), $bits[1])
		else "00"
	let $min :=
		if(exists($bits[2]))
		then concat(string-pad("0", 2 - string-length($bits[2])), $bits[2])
		else "00"
	let $sec :=
		if(exists($bits[3]))
		then concat(string-pad("0", 2 - string-length($bits[3])), $bits[3])
		else "00"
	return string-join(($hours, $min, $sec), ":")
}

define function dates:_processZone(
	$zone as xs:string?
) as xs:string
{
	if(matches($zone, "^[+-]\d\d\d\d$"))
	then concat(substring($zone, 0, 4), ":", substring($zone, 4))
	else if(matches($zone, "\w\w\w"))
	then dates:_zoneLookup($zone)
	else ""
}

define function dates:_zoneLookup(
	$s as xs:string
) as xs:string
{
	let $s := upper-case($s)
	return
		if ($s = "MIT") then "-11:00" else
		if ($s = "HST") then "-10:00" else
		if ($s = "AST") then "-09:00" else
		if ($s = "PST") then "-08:00" else
		if ($s = "MST") then "-07:00" else
		if ($s = "PNT") then "-07:00" else
		if ($s = "CST") then "-06:00" else
		if ($s = "EST") then "-05:00" else
		if ($s = "IET") then "-05:00" else
		if ($s = "PRT") then "-04:00" else
		if ($s = "CNT") then "-03:00" else
		if ($s = "AGT") then "-03:00" else
		if ($s = "BET") then "-03:00" else
		if ($s = "GMT") then "+00:00" else
		if ($s = "UCT") then "+00:00" else
		if ($s = "UTC") then "+00:00" else
		if ($s = "WET") then "+00:00" else
		if ($s = "CET") then "+01:00" else
		if ($s = "ECT") then "+01:00" else
		if ($s = "MET") then "+01:00" else
		if ($s = "ART") then "+02:00" else
		if ($s = "CAT") then "+02:00" else
		if ($s = "EET") then "+02:00" else
		if ($s = "EAT") then "+03:00" else
		if ($s = "NET") then "+04:00" else
		if ($s = "PLT") then "+05:00" else
		if ($s = "IST") then "+05:00" else
		if ($s = "BST") then "+06:00" else
		if ($s = "VST") then "+07:00" else
		if ($s = "CTT") then "+08:00" else
		if ($s = "PRC") then "+08:00" else
		if ($s = "JST") then "+09:00" else
		if ($s = "ROK") then "+09:00" else
		if ($s = "ACT") then "+09:00" else
		if ($s = "AET") then "+10:00" else
		if ($s = "SST") then "+11:00" else
		if ($s = "NST") then "+12:00" else
		if ($s = "PDT") then "-07:00" else
		if ($s = "MDT") then "-06:00" else
		if ($s = "CDT") then "-05:00" else
		if ($s = "EDT") then "-04:00" else
		""
}
