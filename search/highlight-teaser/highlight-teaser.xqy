(:~
 : Mark Logic Highlighted Search Teaser Utiltity 
 :
 : Copyright 2005 Ryan Grimm and O'Reilly Media
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
 : @author Ryan Grimm (grimm@oreilly.com)
 : @version 0.1
 :
 :)

module "http://marklogic.com/commons/highlight-teaser"
declare namespace hlt = "http://marklogic.com/commons/highlight-teaser"
default function namespace = "http://www.w3.org/2003/05/xpath-functions"

(:~
 : This function can be used to return highlighted search teasers.  This
 : function uses the cts:highlight() function that is available in the 3.0 and
 : after versions of Mark Logic.  This function takes in a result element from
 : a search and returns a teaser for that result.  A teaser is a section of text
 : from the result that tries to be representative of the result as a whole.
 :
 : @param $result this is the result element returned from a cts:search()
 :
 : @param $ctsQuery this needs to be the same cts:query() that was used in the cts:search()
 :
 : @param $highlightReplacment this string is used for the expression in the
 : cts:highlight().  Pass it in as a string so you can use $cts:text for example.
 :
 : @param $numChars the number of characters to return in the teaser
 :
 : @return a <teaser/> element with the highlighted blurb inside
 :
 :)
define function hlt:highlight(
	$result as element(),
	$ctsQuery as cts:query*,
	$highlightReplacment as xs:string,
	$numChars as xs:integer
) as element(teaser)
{
	(:
		How this works:
		Step 1:
			Get all of the text out of the element we want to highlight and wrap
			each word that matched in a <match/> element.  Loop over those results and add
			in a @chars attribute, this attribute holds the distance in characters from the
			previous match
		Step 2:
			Find the match that has the least distance to the last match, I'm
			considering this is the most relivate match
		Step 3:
			This is the first step in outputing the limited text blurb.  From the
			most relivant word match, first we will move backwards in the content until no
			more adjoining word matches are reached.
		Step 4:
			Output the most relevant match
		Step 5:
			Output the text after the most relivant match until we have at least
			$numChars characters
		Step 6:
			Limits the outputed text to $numChars characters
		Step 7:
			Highlight the selected text
	:)
	cts:highlight(<teaser>{
		let $total := 0
		let $string := 
			let $counted := <counted>{ (: Step 1 :)
					let $chars := 1
					for $i in cts:highlight(<result>{string-join($result/descendant-or-self::*/text(), " ")}</result>,
						$ctsQuery, <match>{ $cts:text }</match>)/node()
					return
						if(local-name($i) = "match")
						then <match chars="{ $chars }">{ data($i) }</match>
						else (xdmp:set($chars, string-length($i)), $i)
				}</counted>
			let $min := min($counted/match/@chars) (: Step 2 :)
			let $pos := ($counted/match[@chars = $min])[1]
			return concat(
					string-join(		(: Step 3 :)
						let $continue := 2
						for $prev in $pos/preceding-sibling::node()
						return if($continue)
							then if(local-name($prev) = "match")
								then (data($prev), xdmp:set($continue, 1), xdmp:set($total, $total + $prev/@chars))
								else (data($prev), xdmp:set($continue, if($continue = 1) then 0 else $continue))
							else ()
						, " "),
					data($pos),			(: Step 4 :)
					string-join(		(: Step 5 :)
						for $follow in $pos/following-sibling::node()
						return if($total < $numChars)
							then (data($follow), xdmp:set($total, $total + string-length(data($follow))))
							else (), " ")
					)
		return if(string-length($string) > $numChars) then concat(substring($string, 1, $numChars), "...") else $string		(: Step 6 :)
	}</teaser>, $ctsQuery, xdmp:unquote($highlightReplacment))		(: Step 7 :)
}
