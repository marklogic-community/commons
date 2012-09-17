xquery version "0.9-ml"

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
 : @version 1.0
 :
 : @see http://www.parthcomp.com
 : @see http://wp.netscape.com/newsref/std/cookie_spec.html
 :
 :)

module "http://parthcomp.com/cookies"
declare namespace ck="http://parthcomp.com/cookies"

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
define function add-cookie($name as xs:string, $value as xs:string, $expires as xs:dateTime?,
                           $domain as xs:string?, $path as xs:string?, $secure as xs:boolean) as empty()
{
  if(fn:contains($domain, " ") or fn:contains($domain, ",") or fn:contains($domain, ";")) then (
    fn:error("Invalid domain parameter")
  ) else (),

  if(fn:contains($path, " ") or fn:contains($path, ",") or fn:contains($path, ";")) then (
    fn:error("Invalid path parameter")
  ) else (),

  let $cookie := fn:concat(xdmp:url-encode($name), "=", xdmp:url-encode($value))
  let $cookie := if(fn:exists($expires)) then fn:concat($cookie, "; expires=", get-cookie-date-string($expires)) else $cookie
  let $cookie := if(fn:exists($domain)) then fn:concat($cookie, "; domain=", $domain) else $cookie
  let $cookie := if(fn:exists($path)) then fn:concat($cookie, "; path=", $path) else $cookie
  let $cookie := if($secure) then fn:concat($cookie, "; secure") else $cookie
  return xdmp:add-response-header("Set-Cookie", $cookie)
}

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
define function delete-cookie($name as xs:string, $domain as xs:string?, $path as xs:string?) as empty()
{
  add-cookie($name, "", xs:dateTime("1979-11-27T06:23:37"), $domain, $path, fn:false())
}

(:~
 : Retrieves a named cookie from the request headers.
 :
 : @param $name the name of the cookie
 :
 : @return a sequence containing the values for the given cookie name.
 : If no cookies of that name were found, the empty sequence is returned.
 :
 :)
define function get-cookie($name as xs:string) as xs:string*
{
  let $urlname := xdmp:url-encode($name)
  let $header := xdmp:get-request-header("Cookie")
  let $cookies := fn:tokenize($header, "; ?")[fn:starts-with(., fn:concat($urlname,"="))]
  for $c in $cookies
  return xdmp:url-decode(fn:substring-after($c, "="))
}

(:~
 : Retrieves the names of all the cookies available from the request
 : headers.
 :
 : @return a sequence containing the names of the available cookies.
 : If no cookies were found, the empty sequence is returned.
 :
 :)
define function get-cookie-names() as xs:string*
{
  fn:distinct-values(
    let $header := xdmp:get-request-header("Cookie")
    let $cookies := fn:tokenize($header, "; ?")
    for $c in $cookies
    return xdmp:url-decode(fn:substring-before($c, "="))
  )
}

(:~
 : Returns an RFC 822 compliant date string from the given dateTime,
 : that is suitable for use in a cookie header.
 :
 : @param $date the date and time to convert into a string
 :
 : @return the RFC 822 complient date string.
 :
 :)
define function get-cookie-date-string($date as xs:dateTime) as xs:string
{
  let $gmt := xdt:dayTimeDuration("PT0H")
  let $date := fn:adjust-dateTime-to-timezone($date, $gmt)
  let $day := two-digits(fn:get-day-from-dateTime($date))
  let $month := fn:get-month-from-dateTime($date)
  let $year := fn:string(fn:get-year-from-dateTime($date))
  let $hours := two-digits(fn:get-hours-from-dateTime($date))
  let $minutes := two-digits(fn:get-minutes-from-dateTime($date))
  let $seconds := two-digits(xs:integer(fn:round(fn:get-seconds-from-dateTime($date))))
  let $monthNames := ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
  return fn:concat(
    $day, "-",
    $monthNames[$month], "-",
    $year, " ",
    $hours, ":",
    $minutes, ":",
    $seconds, " GMT"
  )
}

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
define function two-digits($num as xs:integer) as xs:string
{
  let $result := fn:string($num)
  let $length := fn:string-length($result)
  return if($length > 2) then fn:substring($result, $length - 1)
    else if($length = 1) then fn:concat("0", $result)
    else if($length = 0) then "00" else $result
}
