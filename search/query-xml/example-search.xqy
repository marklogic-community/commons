(:~
 : Mark Logic Search Example using the Search String to XML Utility
 :
 : Copyright 2005 Ryan Grimm
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
 : @author Ryan Grimm (reaper@iastate.edu)
 : @version 0.1
 :
 : This file contains sample usage of the String to XML Utilty (query-xml.xqy).
 : This script demonstraits how one might go about implementing parts of the
 : Google search interface.  I have not tested this example, it is purly 
 : conceptual.  This is intended to be used as a guide to writing your own
 : search.
:)

import module namespace stox  = "http://marklogic.com/commons/query-xml" at "query-xml.xqy"

(:
	The following function call will produce a XML document like:
	<search>
		<term>http://bob.com</term>
		<term field="allintitle">xquery rocks</term>
		<term op="-" field="allintitle">java</term>
		<term field="site">xquery.com</term>
		<term op="-">xslt</term>
		<term op="-">not this phrase</term>
	</search>
:)
let $xml := stox:searchToXml('http://bob.com allintitle:"xquery rocks" -allintitle:java site:xquery.com -xslt -"not this phrase"',
		("link", "site", "filetype", "allintitle", "allintext", "allinurl", "allinanchor"),
		("+", "-"), ("OR")
)

(: test to see if the search contains anything other then just fields
	if the search does not have any keywords then it can be resolved
	using xquery :)
let $xPathOnly := not($xml//term[not(@field)])

(: fetch all of the documents that match the search criteria :)
let $documents := /html[
	(: title does not contain :)
    if ($xml//term[@field = "allintitle"][@op = "-"])
    then not(cts:contains(./title, cts:or-query(
				for $s in $xml//term[@field = "allintitle"][@op = "-"]
				return cts:word-query(string($s)))
			))
    else true()
    ][
	(: title contains :)
    if ($xml//term[@field = "allintitle"][empty(@op)])
    then cts:contains(./title, cts:or-query(
				for $s in $xml//term[@field = "allintitle"][empty(@op)]
				return cts:word-query(string($s)))
			)
    else true()
    ][
	(: body text does not contain :)
    if ($xml//term[@field = "allintext"][@op = "-"])
    then not(cts:contains(./body, cts:or-query(
				for $s in $xml//term[@field = "allintext"][@op = "-"]
				return cts:word-query(string($s)))
			))
    else true()
    ][
	(: body text contains :)
    if ($xml//term[@field = "allintext"][empty(@op)])
    then cts:contains(./body, cts:or-query(
				for $s in $xml//term[@field = "allintext"][empty(@op)]
				return cts:word-query(string($s)))
			)
    else true()
    ][
	(: not found in the url :)
    if ($xml//term[@field = "allinurl"][@op = "-"])
    then not(cts:contains(./head/meta[@name = "url"]/@content, cts:or-query(
				for $s in $xml//term[@field = "allinurl"][@op = "-"]
				return cts:word-query(string($s)))
			))
    else true()
    ][
	(: found in the url :)
    if ($xml//term[@field = "allinurl"][empty(@op)])
    then cts:contains(./head/meta[@name = "url"]/@content, cts:or-query(
				for $s in $xml//term[@field = "allinurl"][empty(@op)]
				return cts:word-query(string($s)))
			)
    else true()
    ][
	(: not found in any anchors :)
    if ($xml//term[@field = "allinanchor"][@op = "-"])
    then not(cts:contains(.//a, cts:or-query(
				for $s in $xml//term[@field = "allinanchor"][@op = "-"]
				return cts:word-query(string($s)))
			))
    else true()
    ][
	(: found in a anchor :)
    if ($xml//term[@field = "allinanchor"][empty(@op)])
    then cts:contains(.//a, cts:or-query(
				for $s in $xml//term[@field = "allinanchor"][empty(@op)]
				return cts:word-query(string($s)))
			)
    else true()
	]

(: construct a cts:query for the search :)
let $ctsQuery :=
	(: if the search has both positive and negative search terms put it in a cts:and-not-query :)
	if ($xml//term[@op = "-"][empty(@field)] and $xml//term[empty(@op)][empty(@field)])
	then cts:and-not-query(
			cts:and-query(for $s in $xml//term[empty(@op)][empty(@field)] return cts:word-query(string($s))),
			cts:and-query(for $s in $xml//term[@op = "-"][empty(@field)] return cts:word-query(string($s)))
		)
	(: else if the search only contains positive search terms use a cts:word-query inside the cts:query,
		otherwise use a cts:not-query :)
	else if($xml//term[empty(@op)][empty(@field)])
	then cts:and-query(for $s in $xml//term[empty(@op)][empty(@field)] return cts:word-query(string($s)))
	else cts:and-query(for $s in $xml//term[@op = "-"][empty(@field)] return cts:not-query(string($s)))
return
	(: if the search does not contain any search terms, only fields, it can be resolved using xpath :)
	if($xPathOnly)
	then ($documents)[1 to 10]
	else if($documents)
	then cts:search(doc($documents), $ctsQuery)[1 to 10]
	else ()
