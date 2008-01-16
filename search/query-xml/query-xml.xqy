(:~
 : Mark Logic Search String to XML Utility
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
 : @author Ryan Grimm (grimm@xqdev.com)
 : @version 0.5
 :
 :)

module "http://marklogic.com/commons/query-xml"
declare namespace stox = "http://marklogic.com/commons/query-xml"
default function namespace = "http://www.w3.org/2003/05/xpath-functions"


(:~
 : Takes a search string as the input and returns a xml document that can be
 : used in constructing a cts:search()
 :
 : @param $fields list of fields that you would like to be parsed.  For example,
 : if you were google you would set the fields to something like:
 :     ("link", "site", "filetype", "allintitle", "allintext", "allinurl", "allinanchor")
 :
 : @param $operators list of operators that you would like to look for at the
 : beginning of each search term.  If you would like to support negation and
 : thesaurus lookups you could set the operators to:
 :     ("-", "~")
 : Note: The operators can be any character but can only be one character long.
 :
 : @param $modes list of modes that you would like to have parsed out.  This is handy 
 : when you want to enable searches that use words like "OR" or "AND" or "NOT".
 : The two terms that are on either side of the mode will get a mode attribute
 : assinged to them.  The downside is that in some cases you might not know how to 
 : group the modes when constructing your query.
 :
 : @return A xml document that simplifies constructing a query
 :
 :)
define function stox:searchToXml(
	$search as xs:string,
	$fields as xs:string*,
	$operators as xs:string*,
	$modes as xs:string*,
	$pops as xs:string*
) as element(search)
{
	stox:_collapse(
	let $newsearch := string-join(
		if (count(tokenize($search, '"')) > 2)
		then
			for $i at $count in tokenize($search, '"')
			return
				if ($count mod 2 = 0)
				then replace($i, "\s+", "!+!")
				else $i
		else $search, '')
	let $terms := tokenize($newsearch, "\s+")
	for $term at $count in $terms
	let $tokens := tokenize($term, ":")
	let $rawToken := stox:_stripOps($tokens[1], $operators, $pops)
	where not($term = $modes)
	return
		if (count($tokens) > 1)
		then
			if ($fields[. = $rawToken])
			then <term>{ (
					stox:_getMode($modes, $terms, $count)
					,
					stox:_getOp($tokens[1], $operators)
					,
					stox:_getPop($tokens[2], $pops)
					,
					attribute { "field" } { stox:_stripOps($tokens[1], $operators, $pops) }
					,
					replace(string-join($tokens[2 to count($tokens)], ":"), "!\+!", " ")
				) }</term>
			else <term>{ (
					stox:_getMode($modes, $terms, $count)
					,
					stox:_getOp($tokens[1], $operators)
					,
					stox:_getPop($tokens[1], $pops)
					,
					stox:_stripOps(replace(stox:_stripOps(string-join($tokens, ":"), $operators, $pops), "!\+!", " "), $operators, $pops) )
				}</term>
		else if ($tokens[1])
		then <term>{ (
				stox:_getMode($modes, $terms, $count)
				,
				stox:_getOp($tokens[1], $operators)
				,
				stox:_getPop($tokens[1], $pops)
				,
				replace(stox:_stripOps($tokens[1], $operators, $pops), "!\+!", " ")
			) }</term>
		else ()
	)
}

define function stox:_getMode(
	$modes as xs:string*,
	$terms as xs:string*,
	$index as xs:integer
) as attribute()?
{
	if($terms[$index - 1] = $modes or $terms[$index + 1] = $modes)
	then attribute mode { 
		let $prev := $terms[$index - 1]
		let $next := $terms[$index + 1]
		return
			if($next = $modes)
			then $next
			else $prev
	}
	else ()
}

(:~
 : Returns a 'op' attribute if the first character of the given term has one
 : of the specified operators
 :
 : @param $term the search term to get the operator from
 :
 : @param $operators list of operators that you would like to look for in the term
 :
 : @return a 'op' attrubute if the first character of the given term has one of
 : the specified operators
 :)
define function stox:_getOp(
	$term as xs:string,
	$ops as xs:string*
) as attribute()*
{
	let $op := substring($term, 1, 1)
	return
		if ($op = $ops)
		then attribute op { $op }
		else ()
}

define function stox:_getPop(
	$term as xs:string,
	$pops as xs:string*
) as attribute()*
{
	let $pop := substring($term, string-length($term), 1)
	return
		if ($pop = $pops)
		then attribute postop { $pop }
		else ()
}

(:~
 : Removes the leading operator from the term if it exists
 :
 : @param $term the search term to strip the operator from
 :
 : @param $operators list of operators that you would like to look for in the term
 :
 : @return the term with the operator removed if it exists
 :)
define function stox:_stripOps(
	$term as xs:string,
	$ops as xs:string*,
	$pops as xs:string
) as xs:string
{
	let $op := substring($term, 1, 1)
	let $pop := substring($term, string-length($term), 1)
	let $stripedOp :=
		if ($op = $ops)
		then substring($term, 2)
		else $term
	return
		if ($pop = $pops)
		then substring($stripedOp, 1, string-length($stripedOp) - 1)
		else $stripedOp
}

define function stox:_collapse(
	$terms as element(term)*
) as element(search)
{
	<search>{
		let $pos := 0
		for $term in $terms
		let $set := xdmp:set($pos, $pos + 1)
		let $term := $terms[$pos]
		return
			if(exists($term/@field) and string-length($term) = 0)
			then <term>{ (
				$term/@*,
				string($terms[$pos + 1]),
				xdmp:set($pos, $pos + 1)
			) }</term>
			else $terms[$pos]
	}</search>
}
