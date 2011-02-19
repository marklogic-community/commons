xquery version "0.9-ml"
(:~
 : Various Date String Parser
 :
 : Copyright 2008 Ryan Grimm
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
 : @author Ryan Grimm (grimm@xqdev.com) and John Mitchell
 : @version 0.2
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
 : @return if successful, the date is cast as an xs:dateTime
 :)
define function dates:parseDateTime(
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

(:~
 : This function can parse up a ton of different date formats.
 : I'll write up some docs when I get a chance.
 :
 : @return if successful a date element.
 :)
define function dates:parseDate(
	$date as xs:string?
) as element(date)?
{
	if(empty($date))
	then ()
	else
		try {
			(: Remove all spaces and normalize case. :)
			let $date := lower-case(normalize-space($date))

			let $shortCut := dates:_convertShortcutsToTPlusMinus($date)
			let $shortCut := if(exists($shortCut)) then dates:_convertTPlusMinusToDate($shortCut) else ()
			let $today := xdmp:strftime("%Y-%m-%d", current-dateTime())
			let $date :=
				if(exists($shortCut))
				then <date resolution="day">
					<value>{ $shortCut }</value>
					{
						if(xs:date($shortCut) < xs:date($today))
						then <range>
							<start>{ $shortCut }</start>
							<end>{ $today }</end>
						</range>
						else <range>
							<start>{ $today }</start>
							<end>{ $shortCut }</end>
						</range>
					}
				</date>
				else
					let $tFormat := dates:_convertTPlusMinusToDate($date)
					return
						if(exists($tFormat))
						then <date resolution="day">
							<value>{ $tFormat }</value>
							{
								if(xs:date($tFormat) < xs:date($today))
								then <range>
									<start>{ $tFormat }</start>
									<end>{ $today }</end>
								</range>
								else <range>
									<start>{ $today }</start>
									<end>{ $tFormat }</end>
								</range>
							}
						</date>
						else dates:_normalizeDateFormats($date)
			where $date/value castable as xs:date
			return $date
		}
		catch ($e) {
		}
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
	let $month := dates:_monthNameToNumber($bits[$pos])
	let $day := dates:_processDay($bits[$pos - 1])
	let $zone := dates:_processZone($bits[$pos + 3]) (: optional time zone :)
	let $date := concat($year, "-", $month, "-", $day, "T", $bits[$pos + 2], $zone)
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
	let $month := dates:_monthNameToNumber($bits[$pos])
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
	let $month := dates:_monthNameToNumber($bits[$pos])
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
	let $month := dates:_monthNameToNumber($bits[$pos + 1])
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
	let $month := dates:_monthNameToNumber($dateBits[1])
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
	if($year castable as xs:integer)
	then
		if(xs:integer($year) < 100)
		then
			if(xs:integer($year) > 50)
			then concat("19", xs:string(xs:integer($year)))
			else if(xs:integer($year) = 0)
			then "1900"
			else concat("20", string-pad("0", 2 - string-length($year)), $year)
		else if(xs:integer($year) >= 100 and xs:integer($year) < 200)  (: 102 = 2002 in Java :)
		then xs:string(1900 + xs:integer($year))
		else if(xs:integer($year) > 9999)
		then "9999"
		else $year
	else $year
}

define function dates:_monthNameToNumber(
	$month as xs:string?
) as xs:string?
{
	(
		let $months := (
			"jan", "january", "enero", "janvier", "januar", "gennaio",
			"feb", "february", "febrero", "fevrier", "februar", "febbraio",
			"mar", "march", "marzo", "mars", "marz", "marzo",
			"apr", "april", "abril", "avril", "april", "aprile",
			"may", "may", "mayo", "mai", "mai", "maggio",
			"jun", "june", "junio", "juin", "juni", "giugno",
			"jul", "july", "julio", "juillet", "juli", "luglio",
			"aug", "august", "agosto", "aout", "august", "agosto",
			"sep", "september", "septiembre", "septembre", "september", "settembre",
			"oct", "october", "octubre", "octobre", "oktober", "ottobre",
			"nov", "november", "noviembre", "novembre", "november", "novembre",
			"dec", "december", "diciembre", "decembre", "dezember", "dicembre"
		)
		let $monthSansDiacritics := xdmp:diacritic-less($month)
		for $i at $pos in $months
		let $pos := ceiling($pos div 6)
		where $i = $monthSansDiacritics
		return concat(string-pad("0", 2 - string-length(string($pos))), $pos)
	)[1]
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
	if(matches($zone, "[+-]\d\d\d\d"))
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





(:
	Converts the shortcut dates ('yesterday', 'today', 'tomorrow', 'last year',
	'last month', 'last week', 'last day', 'next year', 'next month', 'next
	week', 'next day') into the t format.  If the date doesn't contain any of
	these shortcuts the date itself is returned.

	This function can return pretty much anything.  If garbage characters were
	passed in, you'll get the same garbage back out.
:)
define function dates:_convertShortcutsToTPlusMinus(
	$date as xs:string
) as xs:string?
{
	let $isLast := starts-with($date, "last")
	let $isNext := starts-with($date, "next")

	let $adjustment := if($isNext) then "+" else ""
	let $unit := normalize-space(replace($date, "last|next", ""))
	where not($isLast and $isNext)
	return
		if($date = "yesterday")
		then "t1d"
		else if($date = "today")
		then "t0y"
		else if($date = "tomorrow")
		then "t+1d"
		else if($unit = ("year", "month", "week", "day"))
		then concat(
				"t",
				$adjustment,
				if("year" = $unit)
				then "1y"
				else if("month" = $unit)
				then "1m"
				else if("week" = $unit)
				then "7d"
				else if("day" = $unit)
				then "1d"
				else ""
			)
		else ()
}

(:
	Converts any t date into a string that looks like an xs:date.  If the date
	isn't a t date, then it is just handed back.
:)
define function dates:_convertTPlusMinusToDate(
	$date as xs:string
) as xs:string?
{
	let $now := current-dateTime()
	let $TPMFormat := "t(\+)?([0-9]{1,3}y)?([0-9]{1,3}m)?([0-9]{1,5}d)?"
	let $isTPlusMinus := matches($date, $TPMFormat)
	let $junk := replace($date, concat("(^.*?)", $TPMFormat), "$1")
	where $date != "t" and $date != "t+"
	return
		if($date = ("t0y", "t+0y"))
		then xdmp:strftime("%Y-%m-%d", current-dateTime())
		else if(not($isTPlusMinus) or $junk != "")
		then ()
		else
			(: Extract plus sign, if any. :)
			let $adjPlus := replace($date, $TPMFormat, "$1")

			(: Extract and construct the appropriate durations :)
			let $adjYear := replace($date, $TPMFormat, "$2")
			let $adjMonth := replace($date, $TPMFormat, "$3")
			let $adjDay := replace($date, $TPMFormat, "$4")
			let $ymAdjustment := concat(
					if("" = $adjYear)
					then ()
					else upper-case($adjYear),
					if("" = $adjMonth)
					then ()
					else upper-case($adjMonth)
				)
			let $ymDuration :=
				if("" = $ymAdjustment)
				then ()
				else xdt:yearMonthDuration(concat("P", $ymAdjustment))

			let $dayAdjustment :=
				if($adjDay != "")
				then upper-case($adjDay)
				else ""
			let $dayDuration :=
				if("" = $dayAdjustment)
				then ()
				else xdt:dayTimeDuration(concat("P", $dayAdjustment))

			(: Skip over "t\+?" :)
			let $date :=
				if(starts-with($date, "t+"))
				then substring($date, 3)
				else if(starts-with($date, "t"))
				then substring($date, 2)
				else $date

			(: Adjust the current date by given duration :)
			let $date :=
				if(empty($ymDuration))
				then $now
				else if(empty($adjPlus) or "" = $adjPlus)
				then $now - $ymDuration
				else $now + $ymDuration
			let $date :=
				if(empty($dayDuration))
				then $date
				else if(empty($adjPlus) or "" = $adjPlus)
				then $date - $dayDuration
				else $date + $dayDuration
			return xdmp:strftime("%Y-%m-%d", $date)
}

(:
	Takes in the various date formats and returns a string that can be cast
	into a xs:date.  The date formats can look like:
		2007-08-20
		08-20-2007
		08-20-07
		2007/08/20
		08/20/2007
		08/20/07
		20070820
		December 20, 2005
		Dec 20th, 2005
		December 2006
		September 1st, 2007
:)
define function dates:_normalizeDateFormats(
	$date as xs:string
) as element(date)?
{
	if(contains($date, " ") or contains($date, ", "))
	then
		let $bits := tokenize($date, " |, ")
		let $year :=
			if(count($bits) = 2)
			then dates:_expandYear($bits[2])
			else dates:_expandYear($bits[3])
		let $month := dates:_expandMonth($bits[1])
		let $day :=
			if(count($bits) = 2)
			then dates:_expandDay(())
			else dates:_expandDay(replace($bits[2], "st|nd|rd|th", ""))
		where count($bits) <= 3 and count($bits) > 0
		return <date resolution="{ dates:_getDateResolution($month, $day) }">
			{ dates:_calculateRange($year, $month, $day) }
			<value>{
				string-join((
					string($year),
					string($month),
					string($day)
				), "-")
			}</value>
		</date>
	else if(contains($date, "/") or contains($date, "-"))
	then
		let $bits := tokenize($date, "/|-")
		let $type :=
			if(string-length($bits[1]) = 4 and $bits[1] castable as xs:integer)
			then "year first"
			else "year last"
		let $year :=
			if($type = "year first")
			then $bits[1]
			else $bits[3]
		let $month :=
			if($type = "year first")
			then $bits[2]
			else $bits[1]
		let $day :=
			if($type = "year first")
			then $bits[3]
			else $bits[2]
		let $year := dates:_expandYear($year)
		let $month := dates:_expandMonth($month)
		let $day := dates:_expandDay($day)
		where count($bits) <= 3 and count($bits) > 0
		return <date resolution="{ dates:_getDateResolution($month, $day) }">
			{ dates:_calculateRange($year, $month, $day) }
			<value>{
				string-join((
					string($year),
					string($month),
					string($day)
				), "-")
			}</value>
		</date>
	else if(string-length($date) <= 8)
	then
		let $year := dates:_expandYear(substring($date, 1, 4))
		let $month := dates:_expandMonth(substring($date, 5, 2))
		let $day := dates:_expandDay(substring($date, 7, 2))
		return <date resolution="{ dates:_getDateResolution($month, $day) }">
			{ dates:_calculateRange($year, $month, $day) }
			<value>{
				string-join((
					string($year),
					string($month),
					string($day)
				), "-")
			}</value>
		</date>
	else ()
}

(:
	Because the parser can parse things like "Dec 2005" in some cases we need
	to know the resolution or accuracy of the given date.  In the case of
	"Dec 2005", the resolution would be set to "month" because the date doesn't
	contain any informaiton about the day.  If the date was "2005" the resolution
	would be "year".  If a full date of "2005/12/20" is given then the resolution
	is set to "day".
:)
define function dates:_getDateResolution(
	$month as element(number),
	$day as element(number)
) as xs:string
{
	if($month/@type = "default")
	then "year"
	else if($day/@type = "default")
	then "month"
	else "day"
}

(:
	Because we can parse dates that aren't complete (eg: 'July 1979'), some
	applications need to know a range of dates that the specified date covers.
	For example, in the case of 'July 1979' you might want to find all documents
	published for that month.  So simply returning 1979-07-01 doesn't help
	much.  So to help out, we calculate a start and end date for these cases.
	The start date would be 1979-07-01 and the end date would be 1979-07-31.
	The code is smart enough to always return the last day of the month, even
	if that month is Feb of a new year.
:)
define function dates:_calculateRange(
	$year as element(number),
	$month as element(number),
	$day as element(number)
) as element(range)?
{
	let $resolution := dates:_getDateResolution($month, $day)
	let $start :=
		xs:date(string-join((
			string($year),
			string($month),
			string($day)
		), "-"))
	let $endYear := string($year)
	let $endMonth :=
		if($resolution = "year")
		then "12"
		else string($month)
	let $endDay :=
		if($resolution = ("year", "month"))
		then string(day-from-date(dates:_getLastDayOfTheMonth(xs:integer($endYear), xs:integer($endMonth))))
		else string($month)
	let $end :=
		xs:date(string-join((
			$endYear,
			$endMonth,
			$endDay
		), "-"))
	where $resolution != "day"
	return <range>
		<start>{ $start }</start>
		<end>{ $end }</end>
	</range>
}

(:
	Given a year and a month, this function will return an xs:date of the last
	day of the month.  For example:
		(2007, 6) -> 2007-06-30
		(2007, 7) -> 2007-07-31
		(2007, 2) -> 2007-02-30
		(2008, 2) -> 2007-02-29
	Note that it's smart enough to handle leap years.
:)
define function dates:_getLastDayOfTheMonth(
	$year as xs:integer,
	$month as xs:integer
) as xs:date
{
	let $nextYear :=
		if($month = 12)
		then string($year + 1)
		else string($year)
	let $nextMonth :=
		if($month = 12) 
		then "01"
		else string($month + 1)
	let $nextMonth := concat(string-pad("0", 2 - string-length($nextMonth)), $nextMonth)
	let $nextDate :=
		xs:date(string-join((
			$nextYear,
			$nextMonth,
			"01"
		), "-"))
	return $nextDate - xdt:dayTimeDuration("P1D")
}

(:
	Simply a wrapper around _processYear for some consistancy.
:)
define function dates:_expandYear(
	$year as xs:string?
) as element(number)
{
	<number>{ dates:_processYear($year) }</number>
}

(:
	Takes in a 'month' as a string and returns it as a number.  For example:
		"1" -> "01"
		"01" -> "01"
		"february" -> "06"
		"feb" -> "06"
:)
define function dates:_expandMonth(
	$month as xs:string?
) as element(number)
{
	let $parsedMonth := dates:_monthNameToNumber($month)
	return
		if($parsedMonth)
		then <number type="value">{ $parsedMonth }</number>
		else dates:_expandTwoDigits($month)
}

(:
	Makes sure that the day has a leading 0 if need be.  Empty returns "01".
:)
define function dates:_expandDay(
	$day as xs:string?
) as element(number)
{
	dates:_expandTwoDigits($day)
}

define function dates:_expandTwoDigits(
	$num as xs:string?
) as element(number)
{
	(:
		The first check is designed to see if the value is some bogus input, eg: 2007/foo/bar.
		If $num is less than 0, isn't a number or is empty, return "01".
		Else pad $num with 0's if need be.
	:)
	if(exists($num) and $num != "" and not($num castable as xs:integer))
	then error("Not a valid date")
	else if(empty($num) or not($num castable as xs:integer) or xs:integer($num) <= 0)
	then <number type="default">01</number>
	else <number type="value">{ concat(string-pad("0", 2 - string-length($num)), $num) }</number>
}
