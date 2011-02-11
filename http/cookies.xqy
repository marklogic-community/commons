xquery version "1.0-ml";

(:~
 : Mark Logic CIS Cookie Library
 : 
 : Copyright 2005 Parthenon Computing Ltd.
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
 : @author John Snelson (john@parthcomp.com)
 : @author Geert Josten (geert.josten@daidalos.nl, map:map contribution)
 : @version 1.1
 :
 : @see http://www.parthcomp.com
 : @see http://www.daidalos.nl
 : @see http://wp.netscape.com/newsref/std/cookie_spec.html
 :
 :)

module namespace ck="http://parthcomp.com/cookies";

declare variable $cookies as map:map := map:map();

declare function get-cookie-names() as xs:string* {
	fn:distinct-values((get-cookie-names_(), map:keys($cookies)))
};

declare function get-cookie($name as xs:string) as xs:string
{
	let $value := map:get($cookies, $name)/value
	return
		if ($value) then
			$value
		else
			get-cookie_($name)
};

declare function add-cookie($name as xs:string, $value as xs:string, $expires as xs:dateTime?,
                           $domain as xs:string?, $path as xs:string?, $secure as xs:boolean) as empty-sequence()
{
	map:put($cookies, $name,
		<cookie>
			<value>{$value}</value>
			<expires>{$expires}</expires>
			<domain>{$domain}</domain>
			<path>{$path}</path>
			<secure>{$secure}</secure>
		</cookie>
	)
};

declare function add-cookie($name as xs:string, $value as xs:string) as empty-sequence()
{
	add-cookie($name, $value, (), (), (), fn:false())
};

declare function delete-cookie($name as xs:string) as empty-sequence()
{
	add-cookie($name, "")
};


declare function add-cookie-headers() as empty-sequence()
{
	for $name in map:keys($cookies)
	let $value := map:get($cookies, $name)/value/fn:string(.)
	let $expires := map:get($cookies, $name)/expires[. != '']/xs:dateTime(.)
	let $domain := map:get($cookies, $name)/domain[. != '']/fn:string(.)
	let $path := map:get($cookies, $name)/path[. != '']/fn:string(.)
	let $secure := map:get($cookies, $name)/secure/fn:string(.) = 'true'
	return
		if ($value eq "") then
			delete-cookie_($name, $domain, $path)
		else
			add-cookie_($name, $value, $expires, $domain, $path, $secure)
};

(:~
 : Adds a cookie header to the response headers.
 :
 : @param $name the name of the cookie
 :
 : @param $value the value to store in the cookie
 :
 : @param $expires an optional date and time for the cookie to expire.
 : If this is in the past, the cookie is deleted from the client. If
 : an empty sequence is passed as this parameter, then the cookie will
 : expire when the user's session ends.
 :
 : @param $domain the domain name for which this cookie is valid.
 : If an empty sequence is passed as this parameter, then the domain name
 : or the current server will be used.
 :
 : @param $path the URLs in the domain for which the cookie is valid. This
 : should be a path starting with a "/". If an empty sequence is passed as
 : this parameter, then the cookie behaves as if the path was "/".
 :
 : @param $secure whether this cookie should only be sent over a secure
 : connection.
 :
 : @return ()
 :
 : @error Invalid domain parameter
 : @error Invalid path parameter
 :
 :)
declare function add-cookie_($name as xs:string, $value as xs:string, $expires as xs:dateTime?,
                           $domain as xs:string?, $path as xs:string?, $secure as xs:boolean) as empty-sequence()
{
  if(fn:contains($domain, " ") or fn:contains($domain, ",") or fn:contains($domain, ";")) then (
    fn:error("Invalid domain parameter")
  ) else (),

  if(fn:contains($path, " ") or fn:contains($path, ",") or fn:contains($path, ";")) then (
    fn:error("Invalid path parameter")
  ) else (),

  let $cookie := fn:concat(xdmp:url-encode($name), "=", xdmp:url-encode($value))
  let $cookie := if(fn:exists($expires)) then fn:concat($cookie, "; expires=", get-cookie-date-string_($expires)) else $cookie
  let $cookie := if(fn:exists($domain)) then fn:concat($cookie, "; domain=", $domain) else $cookie
  let $cookie := if(fn:exists($path)) then fn:concat($cookie, "; path=", $path) else $cookie
  let $cookie := if($secure) then fn:concat($cookie, "; secure") else $cookie
  return xdmp:add-response-header("Set-Cookie", $cookie)
};

(:~
 : Adds a cookie header to the response headers, that will delete
 : the specified client side cookie. It is important to specify the
 : correct domain and path for the cookie, otherwise it won't be
 : deleted.
 :
 : @param $name the name of the cookie
 :
 : @param $domain the domain name for which this cookie is valid.
 : If an empty sequence is passed as this parameter, then the domain name
 : or the current server will be used.
 :
 : @param $path the URLs in the domain for which the cookie is valid. This
 : should be a path starting with a "/". If an empty sequence is passed as
 : this parameter, then the cookie behaves as if the path was "/".
 :
 : @return ()
 :
 : @error Invalid domain parameter
 : @error Invalid path parameter
 :
 :)
declare function delete-cookie_($name as xs:string, $domain as xs:string?, $path as xs:string?) as empty-sequence()
{
  add-cookie_($name, "", xs:dateTime("1979-11-27T06:23:37"), (), $path, fn:false())
};

(:~
 : Retrieves a named cookie from the request headers.
 :
 : @param $name the name of the cookie
 :
 : @return a sequence containing the values for the given cookie name.
 : If no cookies of that name were found, the empty sequence is returned.
 :
 :)
declare function get-cookie_($name as xs:string) as xs:string*
{
  let $urlname := xdmp:url-encode($name)
  let $header := xdmp:get-request-header("Cookie")
  let $cookies := fn:tokenize($header, "; ?")[fn:starts-with(., $urlname)]
  for $c in $cookies
  return xdmp:url-decode(fn:substring-after($c, "="))
};

(:~
 : Retrieves the names of all the cookies available from the request
 : headers.
 :
 : @return a sequence containing the names of the available cookies.
 : If no cookies were found, the empty sequence is returned.
 :
 :)
declare function get-cookie-names_() as xs:string*
{
  fn:distinct-values(
    let $header := xdmp:get-request-header("Cookie")
    let $cookies := fn:tokenize($header, "; ?")
    for $c in $cookies
    return xdmp:url-decode(fn:substring-before($c, "="))
  )
};

(:~
 : Returns an RFC 822 compliant date string from the given dateTime,
 : that is suitable for use in a cookie header.
 :
 : @param $date the date and time to convert into a string
 :
 : @return the RFC 822 complient date string.
 :
 :)
declare function get-cookie-date-string_($date as xs:dateTime) as xs:string
{
  let $gmt := xs:dayTimeDuration("PT0H")
  let $date := fn:adjust-dateTime-to-timezone($date, $gmt)
  let $day := two-digits_(fn:day-from-dateTime($date))
  let $month := fn:month-from-dateTime($date)
  let $year := fn:string(fn:year-from-dateTime($date))
  let $hours := two-digits_(fn:hours-from-dateTime($date))
  let $minutes := two-digits_(fn:minutes-from-dateTime($date))
  let $seconds := two-digits_(xs:integer(fn:round(fn:seconds-from-dateTime($date))))
  let $monthNames := ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
  return fn:concat(
    $day, "-",
    $monthNames[$month], "-",
    $year, " ",
    $hours, ":",
    $minutes, ":",
    $seconds, " GMT"
  )
};

(:~
 : Internal function to return a string representation
 : of an integer that contains two digits. If the number
 : has less than two digits it is padded with zeros. If
 : it has more than two digits, it is truncated, and the
 : least significant digits are returned.
 :
 : @param $num the number to convert
 :
 : @return the two digit string
 :
 :)
declare function two-digits_($num as xs:integer) as xs:string
{
  let $result := fn:string($num)
  let $length := fn:string-length($result)
  return if($length > 2) then fn:substring($result, $length - 1)
    else if($length = 1) then fn:concat("0", $result)
    else if($length = 0) then "00" else $result
};
