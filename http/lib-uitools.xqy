(:
 : lib-uitools 
 :
 : Copyright (c)2007 Mark Logic Corporation. All rights reserved.
 :
 :)

(:~
 : Mark Logic User Interface utilities.
 : Utility functions when using XQuery as your UI layer.
 :
 : @author <a href="mailto:chris.welch@marklogic.com">Chris Welch</a>
 : @version 2008-05-27
 :
 :)

module "http://www.marklogic.com/ps/lib/lib-uitools"

(:-- QUERYSTRING FUNCTIONS --:)
(:-- Use these functions as an easy way to pass around and modify
     querystring parameters in your code --:)

(:~
: Converts querystring variables of the current request to an XML fragment.
: NOTE: Values from the xdmp:get-request-field-names() are automatically url-decoded.
: NOTE: MarkLogic makes no distinction between POST and GET fields. 
:
: @returns A element(params) containing elements representing the request fields.
:)
define function load-params() as element(params)
{
	let $params := 
		<params>
		  {for $i in xdmp:get-request-field-names()
		      return
		  		for $j in xdmp:get-request-field($i)
	    	    	return
			       		if ($i ne "") then
	        		    	element {fn:lower-case($i)} {$j}
	        			else ()
		   }
	    </params>
	return $params
}

(:~
 : Useful in faceted searching, this method will take a parameters element
 : and process it. It can remove elements, remove elements with specific values or replace
 : elements with new values.
 : NOTE: A parameter set refers to all parameter elements that share the same name.
 :
 : @param $params A parameters element.
 : @param $set The name of the parameter set to be modified.
 : @param $remove-values Values of the specified set to be removed. All values if empty.
 : @param $new-values New values of the specified set to be inserted. No values inserted if empty.
 : @return A modified parameters element.
 :)
define function modify-param-set(
	$params as element(),
	$set as xs:string,
	$remove-values as xs:string*,
	$new-values as xs:string*
	) as element()
{
	let $newParams :=
		<params>
			{$params/*[fn:local-name(.) != $set or (fn:local-name(.) = $set and fn:count($remove-values) > 0 and fn:not(. = $remove-values))]}
			{for $value in $new-values
			return
				element {$set} {$value}}
		</params>
	return $newParams
}

(:~
 : Useful in faceted searching, this method will take a parameters element
 : and process it. It can remove elements, remove elements with specific values or replace
 : elements with new values.
 :
 : @param $params A parameters element.
 : @param $sets The name of the parameter sets to be removed. No sets will be removed if empty.
 : @param $new-params New parameters to be inserted as-is. No parameters will be inserted if empty.
 : @param A modified parameters element.
 :)
define function modify-param-set(
	$params as element(params),
	$sets as xs:string*,
	$new-params as element()*
	) as element(params)
{
	let $newParams :=
		<params>
			{$params/*[fn:not(fn:local-name(.) = $sets)]}
			{$new-params}
		</params>
	return $newParams
}

(:~
 : Recreate a querystring from the request fields.
 : NOTE: MarkLogic makes no distinction between POST and GET fields. 
 : NOTE: Values from the xdmp:get-request-field-names() are automatically url-decoded.
 :
 : @return A querystring based on the fields of the current request.
 :)
define function rebuild-querystring () as xs:string
{ rebuild-querystring(()) }
(:~
 : Recreate a querystring from the request fields.
 : NOTE: MarkLogic makes no distinction between POST and GET fields. 
 :
 : @param $omit The fields that should be omitted from the new querystring. No sets will be removed if empty.
 : @return A querystring based on the fields of the current request.
 :)
define function rebuild-querystring ($omit as xs:string*) as xs:string
{
    let $variables :=
        for $field in xdmp:get-request-field-names()
        let $vals   := xdmp:get-request-field($field)
        return
            if (fn:not($field = ("", $omit))) then
                for $val in $vals
                return fn:concat($field,"=",xdmp:url-encode($val))
            else ()
    return fn:string-join($variables, "&")
}

(:~
 : Build a querystring from a parameters element. 
 : NOTE: MarkLogic makes no distinction between POST and GET fields. 
 :
 : @param $params The parameters element from which to build the querystring.
 : @return A querystring based on the passed parameters element.
 :)
define function build-querystring($params as element(params)) as xs:string
{ build-querystring($params, ()) }
(:~
 : Build a querystring from a parameters element. 
 : NOTE: MarkLogic makes no distinction between POST and GET fields. 
 :
 : @param $params The parameters element from which to build the querystring.
 : @param $omit The parameter sets that should be omitted from teh new querystring. No sets will be removed if empty.
 : @return A querystring based on the passed parameters element.
 :)
define function build-querystring($params as element(params), $omit as xs:string*) as xs:string
{
	let $args :=
		for $arg in $params/*[if($omit) then fn:not(fn:local-name(.) = $omit) else fn:true()][fn:not(fn:local-name(.) = ("start", "end"))]
		return
		    if ($arg ne "") then
			fn:concat(fn:local-name($arg),"=",xdmp:url-encode(fn:string($arg)))
            else ()
	return
		fn:string-join(fn:distinct-values($args),"&")
}

(:~
 : Given a year, month and day token, will generate an xs:date. Includes validation to
 : ensure a valid xs:date, or will return nothing. No exceptions will be thrown. Useful for
 : search parameters that should be ignored if invalid.
 :
 : @param $year The year string token.
 : @param $month The month string token.
 : @param $day The day string token.
 : @return An xs:date constructed from the passed string tokens.
 :)
define function build-date($year as xs:string?, $month as xs:string?, $day as xs:string?) as xs:date?
{
	if (fn:exists($year) and $year != "" and
		fn:exists($month) and $month != "" and
		fn:exists($day) and $day != "") then
		try {
			xs:date(fn:concat(xs:string(xs:integer($year)),"-",lead-zero(xs:string(xs:integer($month)),2),"-",lead-zero(xs:string(xs:integer($day)),2)))
		} catch ($exception) {
			()
		}
	else ()
}

(:~
 : Returns a sequence of date parameter elements to be passed into a parameters element.
 :
 : @param $date The date to be converted to parameter elements.
 : @param $year-name The name of the year-name element.
 : @param $month-name The name of the month-name element.
 : @param $day-name The name of the day-name element.
 : @return A sequence of three date paramter elements based on the passed date.
 :)
define function get-date-params(
    $date as xs:date,
    $year-name as xs:QName,
    $month-name as xs:QName,
    $day-name as xs:QName) as element()*
{
    let $date-string as xs:string := $date
    return
    (
    element {$year-name} {fn:substring($date-string,1,4)},
    element {$month-name} {fn:substring($date-string,6,2)},
    element {$day-name} {fn:substring($date-string,9,2)}
    )
}

(:~
 : Given a date, and field prefix, will generate a querystring fragment for use in URLs.
 :
 : @param $date The date to be converted to a querystring fragment.
 : @param $prefix The prefix to be used for each field name in the querystring fragment.
 : @return A querystring fragment representing the passed date.
 :)
define function create-date-querystring($date as xs:date, $prefix as xs:string) as xs:string
{
	let $parts := fn:tokenize(fn:string($date),"-")
	let $params := fn:concat($prefix,"-year=",$parts[1],"&",$prefix,"-month=",$parts[2],"&",$prefix,"-day=",$parts[3])
	return
		$params
}

(:-- PAGINATION METHODS --:)

(:~
 : Based on passed values, will determine pagination information for a page.
 :
 : @param $page The current page being viewed.
 : @param $items-per-page The number of items-per-page currently displayed.
 : @param $count The total count of the items in the set.
 : @return A pagination element containing information such as the total number of pages, and start and end item for a given page.
 :)
define function page-info(
	$page as xs:integer,
	$items-per-page as xs:integer,
	$count as xs:integer) as element(pagination)
{
	if ($count <= 0) then
		<pagination>
			<page>0</page>
			<pages>0</pages>
			<start>0</start>
			<end>0</end>
			<count>0</count>
			<items-per-page>{$items-per-page}</items-per-page>
		</pagination>
	else
		let $pages := fn:ceiling($count div $items-per-page)
		let $page := if ($page < 1) then 1 else if ($page > $pages) then $pages else $page
		let $start := (($page - 1) * $items-per-page) + 1
		let $end := $page * $items-per-page
		let $end := if ($end > $count) then $count else $end
		let $previous := $page - 1
		let $next := $page + 1
		return
		<pagination>
			<page>{$page}</page>
			<pages>{$pages}</pages>
			<start>{$start}</start>
			<end>{$end}</end>
			<count>{$count}</count>
			<items-per-page>{$items-per-page}</items-per-page>
			{if ($previous > 0) then <previous>{$previous}</previous> else ()}
			{if ($next <= $pages and $pages > 1) then <next>{$next}</next> else ()}
		</pagination>
}

(:-- UTILITY METHODS --:)

(:~
 : Determines if an item is null or empty. Spaces will also be normalized,
 : so single spaced values will be considered empty.
 :
 : @param $input The value to test.
 : @return A boolean value reflecting whether the item is null or empty, or populated.
 :)
define function is-null-or-empty($input as item()*) as xs:boolean
{
	let $value := fn:true()
	return
	(
	for $i in $input
	return xdmp:set($value, $value and (fn:not(fn:exists($i) and fn:normalize-space(fn:string($i)) ne ""))),
	$value
	)
}

(:~
 : Determines if a number is between (inclusive) two values. The order of the test range $a
 : and $b does not matter.
 :
 : @param $num The number to test.
 : @param $a A bound in the test range.
 : @param $b A bound in the test range.
 : @return A boolean value reflecting whether the number is within the test range or not.
 :)
define function is-between($num as xs:double, $a as xs:double, $b as xs:double) as xs:boolean
{
    if     ( ($num ge $a) and ($num le $b) ) then fn:true()
    else if( ($num le $a) and ($num ge $b) ) then fn:true()
    else fn:false()
}

(:~ Pad a numeric string $int with leading zeros
 :  for a total length of up to $size :)
define function lead-zero($int as xs:string, $size as xs:integer) as xs:string
{
  let $length := fn:string-length($int)
  return
    if ($length lt $size)
    then fn:concat(fn:string-pad("0", $size - $length), $int)
    else $int
}