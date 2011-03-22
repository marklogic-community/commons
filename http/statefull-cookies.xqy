xquery version "1.0-ml";

(:~
 : Statefull Cookie Library
 : 
 : Copyright 2011 Daidalos BV.
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
 : @author Geert Josten (geert.josten@daidalos.nl)
 : @version 1.0
 :
 : @see http://www.daidalos.nl
 : @see cookies.xqy (http://www.parthcomp.com/)
 :)

module namespace sfc="http://daidalos.nl/marklogic/statefull-cookies";

import module namespace ck="http://parthcomp.com/cookies" at "cookies.xqy";

(:~
 : Keeps track of all cookie changes that need to be pushed to the browser at the end of the transaction.
 :)
declare variable $cookies as map:map := map:map();

(:~
 : Wraps around the original ck:get-cookie-names to take cookie cache into account.
 :)
declare function sfc:get-cookie-names() as xs:string* {
	fn:distinct-values((ck:get-cookie-names(), map:keys($cookies)))
};

(:~
 : Wraps around the original ck:get-cookie to take cookie cache into account.
 :)
declare function sfc:get-cookie($name as xs:string) as xs:string
{
	let $value := map:get($cookies, $name)/value
	return
		if ($value) then
			$value
		else
			ck:get-cookie($name)
};

(:~
 : Put all adds to cookie cache only, at first.
 :)
declare function sfc:add-cookie($name as xs:string, $value as xs:string, $expires as xs:dateTime?,
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

(:~
 : Convenience function.
 :)
declare function sfc:add-cookie($name as xs:string, $value as xs:string) as empty-sequence()
{
	sfc:add-cookie($name, $value, (), (), (), fn:false())
};

(:~
 : Convenience function.
 :)
declare function sfc:delete-cookie($name as xs:string) as empty-sequence()
{
	sfc:add-cookie($name, "")
};

(:~
 : Publish cookie headers to browser. Only call once per request, preferably as last statement.
 :)
declare function sfc:add-cookie-headers() as empty-sequence()
{
	for $name in map:keys($cookies)
	let $value := map:get($cookies, $name)/value/fn:string(.)
	let $expires := map:get($cookies, $name)/expires[. != '']/xs:dateTime(.)
	let $domain := map:get($cookies, $name)/domain[. != '']/fn:string(.)
	let $path := map:get($cookies, $name)/path[. != '']/fn:string(.)
	let $secure := map:get($cookies, $name)/secure/fn:string(.) = 'true'
	return
		if ($value eq "") then
			ck:delete-cookie($name, $domain, $path)
		else
			ck:add-cookie($name, $value, $expires, $domain, $path, $secure)
};
