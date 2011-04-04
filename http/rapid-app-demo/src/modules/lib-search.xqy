(:
 : lib-search.xqy
 :
 : Copyright (c) 2007 Mark Logic Corporation. All rights reserved.
 :
 :)

(:~
 : Mark Logic Search Library.
 : This module implements schema agnostic search functionality.
 :
 : Coordinator:
 : @author <a href="mailto:chris.welch@marklogic.com">Chris Welch</a>
 :
 : Contributers (by last name):
 : @author <a href="mailto:rchaudhary@alm.com">Ritesh Chaudhary</a>
 : @author <a href="mailto:james.clippinger@marklogic.com">James Clippinger</a>
 : @author <a href="mailto:frank.rubino@marklogic.com">Frank Rubino</a>
 : @author <a href="mailto:matt.turner@marklogic.com">Matt Turner</a>
 : @author <a href="mailto:gvidal@alm.com">Gary Vidal</a>
 :
 : @requires MarkLogic Server 3.2
 : Format: 3.2-YYYY-MM-DD.[Incremental]
 : @version 3.2-2007-12-13.1
 :
 :)
module "http://www.marklogic.com/ps/lib/lib-search"

import module "http://www.marklogic.com/ps/lib/lib-search" at "lib-search-custom.xqy"
import module namespace lp="http://www.marklogic.com/ps/lib/lib-parser" at "lib-parser.xqy"

declare namespace mlps = "http://www.marklogic.com/ps/lib/lib-mlps"
declare namespace search = "http://www.marklogic.com/ps/lib/lib-search"
declare namespace cfg = "http://www.marklogic.com/ps/lib/lib-search/config"
declare namespace lkup = "http://www.marklogic.com/ps/lib/lib-search/lookup"
declare namespace qm = "http://marklogic.com/xdmp/query-meters"


(:~ The URI of the dictionary to use for all spellchecking applications. :)
define variable $DICTIONARY as xs:string? { ($CONFIG/cfg:dictionary-uri)[1] }
(:~ Controls if debugging is enabled or not :)
define variable $DEBUG as xs:boolean {
    let $val := ($CONFIG/cfg:debug)[1]
    return 
        if ($val) then $val else fn:false()
}
(:~ Maximum number of summarized text nodes to return during resulting summarization. :)
define variable $MAX-SUMMARIZE-MATCHES as xs:integer {
    try {
        xs:integer($CONFIG/cfg:search/cfg:max-summarize-terms)
    } catch ($ex) {
        4
    }}
(:~ Number of words around a highlight match to display. :)
define variable $TRUNCATE-WORDS as xs:integer {
    try {
        xs:integer($CONFIG/cfg:search/cfg:truncate-word-count)
    } catch ($ex) {
        6
    }}

(:~
:
: (Public) Returns a summary of the search results for the given query within the start and end positions.
:
: @param $search-criteria A search:search-criteria element.
: @param $start The first record to be returned.
: @param $end The last record to be returned.
: @return A search:search-summary element containing a sequence of results, resolved facets,
: statistics, phrase and spelling suggestions (if applicable), et al.
:)
define function search-summary($search-criteria as element(search:search-criteria), $start as xs:integer, $end as xs:integer) as element(search:search-summary)
{
    let $start-time := xdmp:query-meters()/qm:elapsed-time

    let $query := build-cts-query($search-criteria)
    let $cts-search-string := build-cts-search-string($search-criteria, $query)
    let $sorted-search-string := build-sorted-search-string($search-criteria, $cts-search-string)
    let $parse-time := xdmp:query-meters()/qm:elapsed-time

    let $results := get-search-results($sorted-search-string, $start, $end)
    let $search-time := xdmp:query-meters()/qm:elapsed-time

    let $estimate := get-adj-search-estimate($cts-search-string, $start, $end, fn:count($results))
    let $estimate-time := xdmp:query-meters()/qm:elapsed-time

    let $spelling-suggestions :=
        let $values :=
            for $i at $pos in $search-criteria/search:term
            return get-spelling-suggestion(fn:string($i/search:text[1]), $pos)
        return
        if ($values) then
        <search:spelling-suggestions>
        {$values}
        </search:spelling-suggestions>
        else ()
    let $processed-results := process-search-results($results, $search-criteria, $query)
    let $summary-time := xdmp:query-meters()/qm:elapsed-time

    let $value-facets := resolve-facets($search-criteria, $search-criteria/search:facet-defs)
    let $facet-time := xdmp:query-meters()/qm:elapsed-time
    return
    <search:search-summary>
        {$spelling-suggestions}
        <search:statistics>
            <search:parse-time>{$parse-time - $start-time}</search:parse-time>
            <search:search-time>{$search-time - $parse-time}</search:search-time>
            <search:estimate-time>{$estimate-time - $search-time}</search:estimate-time>
            <search:summary-time>{$summary-time - $estimate-time}</search:summary-time>
            <search:facet-time>{$facet-time - $summary-time}</search:facet-time>
            <search:total-time>{$facet-time - $start-time}</search:total-time>
        </search:statistics>
        <search:search-results estimate="{$estimate}">
        { $processed-results }
        </search:search-results>
        {$value-facets}
    </search:search-summary>
}

(:~
:
: (Public) Estimates the number of results for the specified search.
:
: @param $search-criteria A search:search-criteria element.
: @return The search estimate.
:)
define function search-estimate($search-criteria as element(search:search-criteria)) as xs:integer
{
 	let $search-string := build-cts-search-string($search-criteria, build-cts-query($search-criteria))
	return
    	get-search-estimate($search-string)
}

(:~
:
: Estimates the number of results for the specified search.
:
: @param $search-string The constructed search string.
: @return The search estimate.
:)
define function get-search-estimate($search-string as xs:string?) as xs:integer
{
    if ($search-string) then
        xdmp:eval(fn:concat(
            construct-prolog(), " ",
            "xdmp:estimate(",$search-string,")"
        ))
    else
        0
}

(:~
:
: Adjusts the search estimate if it detects the current page is the last page.
:
: @param $search-string The constructed search string.
: @param $start The first record to be returned in the relevance ranked list.
: @param $end The last record to be returned in the relevance ranked list.
: @param $actual-page-count The number of items on the current page.
: @return The adjusted search estimate.
:)
define function get-adj-search-estimate(
	$search-string as xs:string?, 
	$start as xs:integer,
	$end as xs:integer,
	$actual-page-count as xs:integer
) as xs:integer
{
	let $estimate := get-search-estimate($search-string)
	let $expected-page-count := $end - $start + 1
	return
		if (($end > $estimate) or $actual-page-count lt $expected-page-count or $actual-page-count = 0) then
			$start + $actual-page-count - 1
		else
			$estimate
}

(:~
:
: (Public) Counts the number of results for the specified search.
:
: @param $search-criteria A search:search-criteria element.
: @return The search count.
:)
define function search-count($search-criteria as element(search:search-criteria)) as xs:integer
{
 	let $search-string := build-cts-search-string($search-criteria, build-cts-query($search-criteria))
	return
    	get-search-count($search-string)
}

(:~
:
: Counts the number of results for the specified search.
:
: @param $search-string The constructed search string.
: @return The search count.
:)
define function get-search-count($search-string as xs:string?) as xs:integer
{
    if ($search-string) then
        xdmp:eval(fn:concat(
            construct-prolog(), " ",
            "fn:count(",$search-string,")"
        ))
    else
        0
}

(:~
:
: (Public) Returns the results of the specified query.
:
: @param $search-criteria A search:search-criteria element.
: @param $start The first record to be returned.
: @param $end The last record to be returned.
: @return The results of the search.
:)
define function search-results($search-criteria as element(search:search-criteria), $start as xs:integer, $end as xs:integer) as node()*
{
  get-search-results(build-search-string($search-criteria, build-cts-query($search-criteria)), $start, $end)
}

(:~
:
: (Public) Returns the results of the specified query.
:
: @param $search-criteria A search:search-criteria element.
: @return All the results of the search.
:)
define function search-results($search-criteria as element(search:search-criteria)) as node()*
{
  get-search-results(build-search-string($search-criteria, build-cts-query($search-criteria)), -1, -1)
}

(:~
:
: Returns the results of the specified search string.
:
: @param $search-string The constructed search string.
: @param $start The first record to be returned.
: @param $end The last record to be returned.
: @return The results of the search.
:)
define function get-search-results($search-string as xs:string?, $start as xs:integer, $end as xs:integer) as node()*
{
    if ($search-string) then
        (
        if ($DEBUG) then xdmp:log(fn:concat("SEARCH STRING: ", $search-string)) else (),
        let $count-pred :=
            if ($start < 1 or $end < 1) then ""
            else fn:concat("[",$start," to ",$end,"]")
        return
        xdmp:eval(fn:concat(
            construct-prolog(), " ",
            if ($DEBUG) then "xdmp:query-trace(fn:true()), " else (),
            "(",$search-string,")",$count-pred,
            if ($DEBUG = fn:true()) then ", xdmp:query-trace(fn:false())" else ()
        ))
        )
    else ()
}

(:~
:
: (Public) Returns a string representation of the search to be executed for debugging purposes
:
: @param $search-criteria A search:search-criteria element
: @return A sorted search string to be evaluated.
:)
define function display-constructed-search($search-criteria as element(search:search-criteria)) as xs:string?
{
    build-search-string($search-criteria, build-cts-query($search-criteria))
}

(:-- Search Summarization Methods --:)

(:~
:
: Extracts and highlights relevant sections of a search result based on the search that
: was executed. Data is returned so that formatting can occur in a calling method.
:
: @param $result The search result element
: @param $search-criteria A search:search-criteria element
: @return The summarized result.
: )
define function summarize-result($result as element(), $query as cts:query, $terms as xs:string*, $tgt-element as element()?) as element(search:result-summary)?
{
	let $results :=
        process-matches($result, $query, $MAX-SUMMARIZE-MATCHES)
    let $results :=
        (
        $results,
        let $diff := $MAX-SUMMARIZE-MATCHES - fn:count($results)
        return
            if ($diff > 0) then
                let $backup-query := cts:or-query(get-words($terms))
                return process-matches($result, $backup-query, $diff)
            else ()
        )
    let $results :=
        if ($tgt-element) then
            transform-match($results, $tgt-element)
        else ()
	return
		if ($results) then
			<search:result-summary>{$results}</search:result-summary>
		else ()
}

define function get-words($terms as xs:string*) as xs:string*
{
    for $term in $terms
    let $words := cts:tokenize($term)[. instance of cts:word]
    return $words
}

define function process-matches($result as element(), $query as cts:query, $qty as xs:integer) as element(search:match-summary)*
{
    let $matches := ($result//(. | node())//text()[cts:contains(.,$query)])[1 to $qty]
    for $hit in $matches
    return
    <search:match-summary>
        <search:path>{xpath($hit)}</search:path>
        <search:content>{truncate-text(cts:highlight(<search:wrapper>{$hit}</search:wrapper>,$query,<search:match>{$cts:text}</search:match>))}</search:content>
    </search:match-summary>
}

define function transform-match($nodes as node()*, $tgt-element as element()?) as node()*
{
	for $x in $nodes return
	typeswitch ($x)
	case element(search:match) return
	    element
	        {fn:node-name($tgt-element)}
	        {
	            $tgt-element/attribute::*,
	            $x/node()
	        }
	case element() return
        element
        	{fn:node-name($x)} 
    		{
    			$x/attribute::*,
    			for $z in $x/node() return transform-match($z, $tgt-element)
    		}
  default return $x
}
:)

(:~
:
: Returns the configured number of words before and after the highlight term.
:
: @param $x An item to be trucated.
: @return The truncated text.
:)
define function truncate-text($x as item()) as item()*
{
    if (fn:empty($x)) then () else
       typeswitch($x)
       case text() return
            (: is there a highlight node before? :)
             (if ( $x/preceding-sibling::node()[1][self::search:match] )
                     then ((: if so, print the first $g_num words :)
                        let $tokens := cts:tokenize($x)
                        let $count := fn:count($tokens)
                        let $truncateTokens := if ( $count < $TRUNCATE-WORDS ) (: > :)
                                          then ( $tokens )
                                          else ( $tokens[1 to $TRUNCATE-WORDS] )
                        return
                        if ( $count < $TRUNCATE-WORDS ) (: > :)
                        then ( (: is there a highlight node after? :)
                              if ( $x/following-sibling::node()[1][self::search:match] )
                              then ( (: if there is a highlight node after, we do
                                        not want to double count it :) )
                              else (
                                fn:concat(
                   (: If the first token is punctuation, then no space before :)
                                 if ($tokens[1] instance of cts:punctuation )
                                 then ("")
                                 else (" "), fn:string-join($tokens, "") )
                             ) )
                        else ( fn:concat(
                     (: If the first token is punctuation, then no space before :)
                                 if ($truncateTokens[1] instance of cts:punctuation )
                                 then ("")
                                 else (" "), fn:string-join( $truncateTokens , ""),
                                      " ")
                             )
                      )

                     else (""),
            (: is there a highlight node after? :)
            if ( $x/following-sibling::node()[1][self::search:match] )
            then ( (: if so, print the last $g_num words :)
                     let $tokens := cts:tokenize($x)
                     let $count := fn:count($tokens)
                     let $truncateTokens := if ( $count < $TRUNCATE-WORDS )  (: > :)
                                 then ( $tokens )
                                 else ( $tokens[fn:last() - $TRUNCATE-WORDS to fn:last()] )
                     return
                     if ( $count < $TRUNCATE-WORDS ) (: > :)
                     then ( fn:concat(fn:string-join($tokens, ""),
                  (: If the last token is not punctuation, then add space after :)
                               if (fn:not($tokens[fn:last()] instance of cts:punctuation) )
                               then (" ")
                               else ("") )
                           )
                     else ( fn:concat(fn:string-join( $truncateTokens , ""),
                  (: If the last token is not punctuation, then add space after :)
                               if (fn:not($tokens[fn:last()] instance of cts:punctuation) )
                               then (" ")
                               else ("") )
                           )
                   )
              else ("" )
               )
       case element (search:match) return $x
       default return for $z in $x/node() return truncate-text($z)
}

(:-- Search Parsing Methods --:)

(:~
:
: Constructs the search string that will be evaulated by the search-results function.
:
: @param $search-criteria A search:search-criteria element
: @param $query A pre-parsed cts:query value
: @return A sorted search string to be evaluated.
:)
define function build-search-string($search-criteria as element(search:search-criteria), $query as cts:query?) as xs:string?
{
    let $cts-search-string := build-cts-search-string($search-criteria, $query)
    let $sorted-search-string := build-sorted-search-string($search-criteria, $cts-search-string)
    return $sorted-search-string
}

(:~
:
: Constructs a sorted cts:search string that will be evaulated by search-results.
:
: @param $search-criteria A search:search-criteria element
: @param $search-string The result of a call to build-cts-search-string
: @return A sorted search string to be evaluated.
:)
define function build-sorted-search-string($search-criteria as element(search:search-criteria), $search-string as xs:string?) as xs:string?
{
	if ($search-string and $search-criteria/search:sort) then
		let $cfg-sort-field := ($CONFIG/cfg:search/cfg:sort-fields/cfg:sort-field[@id = $search-criteria/search:sort/search:sort-field-id])[1]
	    let $sort-field := $search-criteria/search:sort[1]/search:sort-field[1]
	    let $sort-field := if ($sort-field) then $sort-field else $cfg-sort-field
	    let $direction := fn:lower-case(fn:string(($search-criteria/search:sort[1]/search:direction[1], $sort-field/@direction)[1] ))
		let $direction := if ($direction = ("ascending", "descending")) then $direction else ()
		let $type := fn:string($sort-field/@type)
		let $field := fn:string($sort-field)
		return
			if (fn:string($sort-field) and fn:string($type)) then
				fn:concat(
					"for $result in ", $search-string, " ",
					"order by ", $type, "($result/", $field, ") ", $direction, " ",
					"return $result"
				)
			else
			    if ($search-criteria/search:sort/search:sort-field-id and fn:not($cfg-sort-field)) then
				    fn:error(fn:concat("Sort Field ID '", fn:string($search-criteria/search:sort/search:sort-field-id), "' could not be resolved."))
				else
				    fn:error(fn:concat("Sort field was not properly configured. Must contain XPath and 'type' attribute."))
	else
		$search-string
}

(:~
:
: Constructs a search string that will be evaluated by search-results.
:
: @param $search-criteria A search:search-criteria element
: @param $query A pre-parsed cts:query value
: @return A search string to be evaluated.
:)
define function build-cts-search-string($search-criteria as element(search:search-criteria), $query as cts:query?) as xs:string?
{
    let $fast-paging :=
        try { xs:boolean(fn:string($search-criteria/@fast-pagination)) }
        catch ($exp)
        { fn:false() }
    let $allow-empty-terms :=
        try { xs:boolean(fn:string($search-criteria/@allow-empty-terms)) }
        catch ($exp)
        { fn:true() }
    let $valid-search := fn:not( fn:not($allow-empty-terms) and fn:empty($query) )
    return
        let $search-path :=
            if ($search-criteria/search:search-path) then
                fn:string($search-criteria/search:search-path[1])
            else
                fn:string(($CONFIG/cfg:search/cfg:search-path)[1])
        return
        if (fn:string($query)) then
            fn:concat("cts:search(fn:doc()",$search-path,",",$query, if ($fast-paging) then ", 'unfiltered'" else (), ")")
        else if ($valid-search) then
            fn:concat("fn:doc()",$search-path)
        else ()
}

(:~
:
: Constructs a cts:query value that represents the "right-hand" part of the passed search.
:
: @param $search-criteria A search:search-criteria element
: @return A cts:query value.
:)
define function build-cts-query($search-criteria as element(search:search-criteria)) as cts:query?
{
    let $compatibility-check := search-compatibility-check($search-criteria)
    let $search-criteria := combine-base-criteria($CONFIG/cfg:search/cfg:base-criteria, $search-criteria)
    let $search-criteria := resolve($search-criteria)
    let $allow-empty-terms :=
        try { xs:boolean(fn:string($search-criteria/@allow-empty-terms)) }
        catch ($exp)
        { fn:true() }
    let $text-query :=
    	traverse-ops($search-criteria/(search:term|search:op), "and")
	(: This function isn't parsed recursively because the following line has to occur, and
	   I haven't worked through it with recursion yet. :)
	let $valid-search := 
	    ($text-query or ($allow-empty-terms and fn:empty($text-query)))
    let $value-queries :=
		build-value-query((
		    $search-criteria/search:values
		    ))

	let $collection-query :=
	    build-collection-query($search-criteria/search:collections)
	let $directory-query :=
        build-directory-query($search-criteria/search:directories)
    let $date-query := 
    	for $date-range in $search-criteria/search:date-range return
    	build-date-query(resolve(($CONFIG/cfg:search/cfg:date-field/(search:element|search:element-attr|search:scope-id))[1]),$date-range)
    let $cts-query :=
	    lp:deserialize-query($search-criteria/cts:*)
	
	let $query-parts :=
	    ($text-query, $value-queries, $collection-query, $directory-query, $date-query, $cts-query)
	return
	    if ($valid-search) then
	        let $count := fn:count($query-parts) return
	        if ($count > 1) then
		        cts:and-query($query-parts)
		    else if ($count = 1) then
		        $query-parts
		    else ()
		else ()
}

(:~
: Combines the base search criteria and the user's search criteria into one XML fragment.
:
: @param $base-criteria The base search criteria.
: @param $search-criteria The user-specified search criteria.
: @return A single search-criteria element with the criteria of both parameters.
:)
define function combine-base-criteria(
    $base-criteria as element(cfg:base-criteria)?,
    $search-criteria as element(search:search-criteria)) as element(search:search-criteria)
{
    <search:search-criteria>
        {$search-criteria/@*}
        {$search-criteria/node()}
        {$base-criteria/node()}
    </search:search-criteria>
}

(:~
: Checks the compatibility of the search-criteria and configuration XML to ensure that users that have upgraded
: will not have undiscovered bugs. Incompatibilities will result in an error being thrown.
:
: @returns Nothing.
:)
define function search-compatibility-check($search-criteria as element(search:search-criteria))
{
    if ($DEBUG) then
        (:():)
        if ($search-criteria//search:field or $CONFIG//search:field) then
            fn:error("Compatibility Check: search:field has been replaced by search:element and search:element-attr. Please update your code and configuration accordingly.")
        else if ($search-criteria//search:field-id or $CONFIG//search:field-id) then
            fn:error("Compatibility Check: search:field-id has been renamed search:scope-id. Please update your code and configuration accordingly.")
        else if ($CONFIG/cfg:search/cfg:lefthand-path) then
            fn:error("Compatibility Check: cfg:search/cfg:lefthand-path is no longer a supported configuration. Use cfg:search/cfg:search-path instead.")
        else if ($CONFIG/cfg:search/cfg:exec-prolog) then
            fn:error("Compatibility Check: cfg:search/cfg:exec-prolog is no longer a supported configuration. Use cfg:search/cfg:namespaces instead.")
        else if ($CONFIG/cfg:search/mlps:search-field-map) then
            fn:error("Compatibility Check: lib-parser.xqy has changed its namespace from 'http://www.marklogic.com/ps/lib/lib-mlps' to 'http://www.marklogic.com/ps/lib/lib-parser'. Please change your config file accordingly.")
        else if ($search-criteria/search:field-values) then
            fn:error("Compatibility Check: search:search-criteria/search:field-values has been renamed to search:search-criteria/search:values. Please update your code accordingly.")
        else if ($CONFIG/cfg:search/cfg:search-dirs) then
            fn:error("Compatibility Check: cfg:search/cfg:search-dirs is no longer a supported configuration. Use cfg:search/cfg:base-criteria instead.")
        else ()
    else ()
}

(:~
: Checks the compatibility of the facet-def and configuration XML to ensure that users that have upgraded
: will not have undiscovered bugs. Incompatibilities will result in an error being thrown.
:
: @returns Nothing.
:)
define function facet-compatibility-check($search-facet as element(search:facet-def))
{
    if ($DEBUG) then
        if ($search-facet//search:field or $CONFIG//search:field) then
            fn:error("Compatibility Check: search:field has been replaced by search:element and search:element-attr. Please update your code and configuration accordingly.")
        else if ($search-facet//search:field-id or $CONFIG//search:field-id) then
            fn:error("Compatibility Check: search:field-id has been renamed search:scope-id. Please update your code and configuration accordingly.")
        else if ($CONFIG//search:field-facet or $search-facet/search:field-facet) then
            fn:error("Compatibility Check: search:field-facet has been changed to search:value-facet. Please update your code or configuration file accordingly.")
        else ()
    else ()
}

(:~
: Constructs a module prolog for use in xdmp:eval statements.
:
: @return The constructed module prolog.
:)
define function construct-prolog() as xs:string?
{
    fn:string-join(
    for $ns in $CONFIG/cfg:search/cfg:namespaces/cfg:namespace
    return fn:concat("declare namespace ",fn:data($ns/@prefix),"='",fn:data($ns),"' ")
    , "")
}

(:-- Free-Text Methods --:)

(:~ 
: 
: Constructs a cts:query value that represents the passed term queries.
:
: @param $items A sequence of search:term and search:op elements
: @param $operator Operator to connect this set of terms/operators with
: @return A cts:query value.
:)
define function traverse-ops($items as element()*, $operator as xs:string) as cts:query?
{
	let $check-op :=
	    if (fn:not($operator = ("and", "or", "not", "near"))) then
	        fn:error(fn:concat("Operator '", $operator, "' passed to traverse-ops() is not valid; options are ""and"", ""or"", ""not"", and ""near"""))
	    else ()
	let $cts-queries := 
		for $item in $items
		return
			typeswitch ($item)
			case element(search:term) return
			    build-term-query($item)
			case element(search:op) return
                traverse-ops($item/*, fn:lower-case(fn:string($item/@type)))
			default return
                fn:error("Search criteria passed inside search:op that is not a search:term")
	return
        let $count := fn:count($cts-queries) return
        if ($count > 1) then
    		if ($operator eq "and") then
    			cts:and-query($cts-queries)
    		else if ($operator eq "or") then
    			cts:or-query($cts-queries)
    		else if ($operator eq "not") then
    			cts:not-query(cts:or-query($cts-queries))
    		else if ($operator eq "near") then
    			cts:near-query($cts-queries)
    		else ()
        else if ($count = 1) then
    		if ($operator eq "not") then
    			cts:not-query($cts-queries)
    	    else $cts-queries
        else ()
}

(:~
:
: Constructs a cts:query value that represents the passed text queries. The
: search terms will be parsed and combined with any field definitions present to
: perform a fielded search. If multiple fields are defined in the term, the
: cts:query will inlcude a cts:or-query of the cts:element-queries representing each
: field.
:
: @param $search-criteria A search:search-criteria element
: @return A cts:query value.
:)
define function build-term-query($terms as element(search:term)*) as cts:query?
{
	let $cts-queries := 
		for $term in $terms
		let $text := $term/search:text[1]
		return
			if (fn:string($text)) then
                let $element-qnames :=
    				for $element in $term/search:element
    				return safe-QName(($element/search:namespace)[1], ($element/search:local-name)[1])
				let $term-query :=
    				if ($text/@parser = "basic") then
        			    let $mode as xs:string :=
        			        if ($text/@mode and fn:lower-case($text/@mode) = ("any", "all", "exact")) then
        			            $text/@mode
        			        else "all"
        			    return
        			        basic-text-parser($text, $mode,
            			        ("case-insensitive",
                                "diacritic-insensitive",
                                "punctuation-sensitive"))
        			else (: lib-parser is the default parser :)
        				let $field-map :=
        					(: Disable inline fielded search if the term is already fielded :)
        					if ($element-qnames) then
                                <lp:search-field-map />
                            else
                                let $user-map := ($CONFIG/cfg:search/lp:search-field-map)[1]
                                return if ($user-map) then $user-map else <lp:search-field-map />
                        return
                            lp:get-cts-query($text, $field-map,
                                ("case-insensitive",
                                "diacritic-insensitive",
                                "punctuation-sensitive") )
                return
                    if ($element-qnames and fn:exists($term-query)) then
                        cts:element-query($element-qnames, $term-query)
                    else
                        $term-query
            else ()
    return
        let $count := fn:count($cts-queries) return
        if ($count > 1) then
            cts:and-query($cts-queries)
        else if ($count = 1) then
            $cts-queries
        else ()
}

(: Returns the text-search portion of the query :)
define function basic-text-parser(
	$text as xs:string,
	$mode as xs:string,
	$options as xs:string*
	) as cts:query
{
	(: A facility to clean the input text :)
	(:let $clean-text-tokens := 
		for $token in cts:tokenize($text)
		return
			typeswitch ($token)
			case cts:word return $token
			case cts:punctuation return if ($token = ("-")) then $token else ()
			case cts:space return $token
			default return ()
	let $text :=
		fn:string-join($clean-text-tokens, ""):)
		
	let $search-tokens :=
		fn:tokenize($text," ")
	return
		if ($mode eq "exact" or fn:count($search-tokens) eq 1) then
			cts:word-query($text, $options)
		else if ($mode eq "any") then
			cts:or-query(
			    for $search-token in $search-tokens
			    return cts:word-query($search-token, $options)
			)
		else (: "all" :)
			cts:and-query(
			    for $search-token in $search-tokens
			    return cts:word-query($search-token, $options)
		    )
}

(:~
:
: Constructs a suggested spelling based on the dictionary loaded in the database.
:
: @param $term The string to test.
: @return A cts:query value.
:)
define function get-spelling-suggestion($term as xs:string?, $position as xs:integer?) as element(search:spelling-suggestion)?
{
    if (fn:string($DICTIONARY) and $term) then
	    let $sugg-phrase := phrase-spell-suggest($term)
	    return
		    if (fn:compare($term, $sugg-phrase) != 0) then
		        <search:spelling-suggestion>
		            { if ($position) then attribute position {$position} else () }
		            <search:original>{$term}</search:original>
		            <search:suggested>{$sugg-phrase}</search:suggested>
		        </search:spelling-suggestion>
		    else ()
	else ()
}

(:~
:
: Returns the "best" spelling suggestion for the given phrase.
:
: @param $term The term to be corrected of all spelling suggestions.
: @return The corrected phrase.  If the given phrase is correct, it will be returned.
:)
define function phrase-spell-suggest($term as xs:string) as xs:string
{
    fn:string-join(
    for $token in cts:tokenize($term)
    return
    	typeswitch ($token)
        case $token as cts:word return
            if (fn:not($token = ("NEAR", "NOT", "OR")) and fn:not(spell:is-correct($DICTIONARY, $token))) then
                spell:suggest($DICTIONARY, $token)[1]
            else xs:string($token)
        default return xs:string($token)
    ,"")
}

(:-- Query Builder Methods --:)

(:~
:
: Builds a date range query to be used when evaluating a search expression. Supports both
: discrete date ranges as well as trailing date durations.
:
: @param $date-field The field to be tested in the inequality. This field must have a xs:date range index.
: @param $date-range The date range element to use to create the predicate.
: @return The string date query.
:)
define function build-date-query($date-field as element()?, $date-range as element(search:date-range)?) as cts:query?
{
    let $start-elem := fn:string($date-range/search:from)
    let $end-elem := fn:string($date-range/search:to)
    let $base-date-elem := fn:string($date-range/search:base-date)
    let $duration-elem := fn:string($date-range/search:trailing-duration)
    let $is-range := ($start-elem or $end-elem)
    let $is-duration := $duration-elem
    return
        if ($is-range) then
            let $start-date := if ($start-elem) then xs:date($start-elem) else ()
            let $end-date := if ($end-elem) then xs:date($end-elem) else ()
            return build-date-query($date-field,$start-date,$end-date)
        else if ($is-duration) then
            let $duration := xdt:dayTimeDuration($duration-elem)
            let $end-date := if ($base-date-elem) then xs:date($base-date-elem) else fn:current-date()
            let $start-date :=  $end-date - $duration
            return build-date-query($date-field,$start-date,$end-date)
        else ()
}

(:~
:
: Builds a date range query to be used when evaluating a search expression.
:
: @param $date-field The field to be tested in the inequality. This field must have a xs:date range index.
: @param $start-date The starting date for the inequality. If null, all previous dates are used.
: @param $end-date The ending date for the inequality. If null, all future dates are used.
: @return The string date predicate.
:)
define function build-date-query($date-field as element()?, $start-date as xs:date?, $end-date as xs:date?) as cts:query?
{
    if ((fn:exists($start-date) or fn:exists($end-date))) then
        if ($date-field) then
            let $options := ()
            let $options :=
                    if ($CONFIG/cfg:search/cfg:collation) then
                        ($options, fn:concat("collation=",$CONFIG/cfg:search/cfg:collation))
                    else $options
                    
            let $scope := $date-field
            let $element-qname := safe-QName(($scope/search:namespace)[1], ($scope/search:local-name)[1])
            let $element-attr-qname :=
                if ($scope instance of element(search:element-attr)) then
                    safe-QName(($scope/search:attr-namespace)[1], ($scope/search:attr-local-name)[1])
                else ()
        
            let $start-test :=
                if ($start-date) then
                    if ($element-attr-qname) then
                        cts:element-attribute-range-query($element-qname, $element-attr-qname,
                            ">=", $start-date, $options)
                    else
                        cts:element-range-query($element-qname,
                          ">=", $start-date, $options)
                else ()
            let $end-test :=
                if ($end-date) then
                    if ($element-attr-qname) then
                        cts:element-attribute-range-query($element-qname, $element-attr-qname,
                            "<=", $end-date, $options)
                    else
                        cts:element-range-query($element-qname,
                            "<=", $end-date, $options)
                else ()
            let $query :=
                if (fn:exists($start-test) and fn:exists($end-test)) then
                    cts:and-query(($start-test,$end-test))
                else
                    ($start-test,$end-test)
            return
                $query
        else
            fn:error("Date field must be configured to use date range criteria")
    else
        ()
}

(:~
:
: Builds a cts:query value to search in the specified collections. Operator between collection
: groups is AND, and the operators within a collection group is OR.
:
: @param $collections The collections to search in
: @return The constructed cts:query variable.
:)
define function build-collection-query($collection-groups as element(search:collections)*) as cts:query?
{
    let $collection-queries :=
        for $group in $collection-groups
        let $coll-set-cfg := get-collection-set($group/search:set-id[1])
        let $collections :=
          if (fn:not(fn:string($group/search:set-id)) or $coll-set-cfg) then
              for $value in $group/search:value
              return fn:concat(fn:string($coll-set-cfg/cfg:base-uri), fn:string($value))
          else ()
        return
          if ($collections) then
              (: Default join operator is cts:or-query :)
              cts:collection-query($collections)
          else ()
    return
        let $count := fn:count($collection-queries) return
        if ($count > 1) then
          cts:and-query($collection-queries)
        else if ($count = 1) then
          $collection-queries
        else ()
}

(:~
:
: Builds a cts:query value to search in the specified directories. The
: operators within a directory group is OR.
:
: @param $directory-uris The directories to search in.
: @param $depth The depth of the search.
: @return The constructed cts:query variable.
:)
define function build-directory-query($directory-groups as element(search:directories)*) as cts:query?
{
    let $directory-queries :=
        for $directory-group in $directory-groups
        let $directory-uris as xs:string* := $directory-group/search:directory
        let $depth as xs:string? := $directory-group/@depth
        return
            if ($directory-uris) then
                if ($depth) then
                    cts:directory-query($directory-uris, $depth)
                else
                    cts:directory-query($directory-uris)
            else ()
    return
        let $count := fn:count($directory-queries) return
        if ($count > 1) then
            cts:and-query($directory-queries)
        else if ($count = 1) then
            $directory-queries
        else ()
}

(:~
:
: A function to build a cts:query value to match values in a specific element or element-attr.
: If present, range indexes will be utilized. All values must match with case, punctionation
: and diacritics.
:
: @param $value-groups A value element that represents an element or element-attr and
:        associated values to include in the search.
: @return A cts:query object
:)
define function build-value-query($value-groups as element(search:values)*) as cts:query?
{
    let $value-queries :=
        for $value-group in $value-groups
        return
            let $scope := $value-group/(search:element|search:element-attr)[1]
            let $element-qname := safe-QName(($scope/search:namespace)[1], ($scope/search:local-name)[1])
            let $element-attr-qname :=
                if ($scope instance of element(search:element-attr)) then
                    safe-QName(($scope/search:attr-namespace)[1], ($scope/search:attr-local-name)[1])
                else ()
            return
                if ($element-attr-qname) then
                    cts:element-attribute-value-query($element-qname, $element-attr-qname,
                        $value-group/search:value, ("case-sensitive", "diacritic-sensitive", "punctuation-sensitive"))
                else
                    cts:element-value-query($element-qname,
                        $value-group/search:value, ("case-sensitive", "diacritic-sensitive", "punctuation-sensitive"))
    return
        let $count := fn:count($value-queries) return
        if ($count > 1) then
            cts:and-query($value-queries)
        else if ($count = 1) then
            $value-queries
        else ()
}

(:~
:
: Retrieve the collection set of the requested ID.
:
: @param $id The ID of the requested collection set.
: @return The collection set element if it was found.
:)
define function get-collection-set($id as xs:string?) as element(cfg:collection-set)?
{
    if ($id) then
        let $coll-set-cfg := ($CONFIG/cfg:collection-sets/cfg:collection-set[@id = $id])[1]
        return
            if ($coll-set-cfg) then
                $coll-set-cfg
            else
                fn:error(fn:concat("Collection set '", $id, "' could not be found"))
    else ()
}

(:~
:
: Returns an fn:expanded-QName that is safe to be used in xdmp:eval.
:
: @param $namespace The namespace URI to be used to construct the QName.
: @param $local-name The local name to be used to construct the QName.
: @return A safe fn:expanded-QName.
:)
define function safe-QName($namespace as xs:string?, $local-name as xs:string)
{
    let $namespace := fn:string(escape-string($namespace))
    let $local-name := $local-name
    return fn:expanded-QName($namespace, $local-name)
}

(:~
:
: Returns a string that has been escaped and is safe to be used in xdmp:eval.
:
: @param $string A string to be escaped.
: @return A escaped and safe xs:string.
:)
define function escape-string($string as xs:string?)
{
    let $string := fn:replace($string, "&", "&amp;amp;")
    let $string := fn:replace($string, """", "&amp;quot;")
    return $string
}

(:-- Generic Facet Methods --:)

(:~
:
: Resolves the requested facet for the passed search. Resolution involves determining the in-scope values, then
: counting the instances of those values within the search results.
: NOTE: An exception will be thrown if a xs:string range index is not present on the requested
: element or element-attr.
:
: @param $search-criteria A search:search-criteria element representing the search.
: @param $facet-defs The facets to resolve
: @return A fully resolved set of facets.
:)
define function resolve-facets(
  $search-criteria as element(search:search-criteria),
  $facet-defs as element(search:facet-defs)?
) as element(search:facets)?
{
    let $search-criteria := resolve($search-criteria)
    let $facet-defs := resolve($facet-defs)
    let $facets :=
        for $i in $facet-defs/search:facet-def
        return resolve-facet($search-criteria, $i)
    return
        if ($facets) then
            <search:facets>{$facets}</search:facets>
        else ()
}

(:~
:
: Resolves the requested facet for the passed search. Resolution involves determining the in-scope values, then
: counting the instances of those values within the search results.
: NOTE: An exception will be thrown if a xs:string range index is not present on the requested
: element or element-attr.
:
: @param $search-criteria A search:search-criteria element representing the search.
: @param $facet-def The facet to resolve
: @return A fully resolved facet.
:)
define function resolve-facet(
  $search-criteria as element(search:search-criteria),
  $facet-def as element(search:facet-def)?
) as element(search:facet)?
{
    let $compatibility-check := facet-compatibility-check($facet-def)
    let $search-criteria := resolve($search-criteria)
    let $facet-def := resolve($facet-def)
    let $facet :=
        typeswitch ($facet-def/*[1])
        case element(search:value-facet) return resolve-value-facet($search-criteria, $facet-def)
        case element(search:collection-set-facet) return resolve-collection-set-facet($search-criteria, $facet-def)
        case element(search:date-group-facet) return resolve-date-group-facet($search-criteria, $facet-def)
        case element(search:trailing-date-facet) return resolve-trailing-date-facet($search-criteria, $facet-def)
        default return ()
    return
        if ($facet) then
            resolve-facet-values($facet)
        else ()
}

(:-- Value Facet Methods --:)

(:~
:
: Resolves the requested value facet for the passed search. Resolution involves determining
: the in-scope values, then counting the instances of those values within the search results.
: NOTE: An exception will be thrown if a xs:string range index is not present on the requested
: element or element-attr.
:
: @param $search-criteria A search:search-criteria element representing the search.
: @param $facet-def The value facet to resolve
: @return A fully resolved value facet.
:)
define function resolve-value-facet(
  $search-criteria as element(search:search-criteria),
  $facet-def as element(search:facet-def)
) as element(search:facet)
{
    let $scope := $facet-def/search:value-facet/(search:element|search:element-attr)[1]
    let $element-qname := safe-QName(($scope/search:namespace)[1], ($scope/search:local-name)[1])
    let $element-attr-qname :=
        if ($scope instance of element(search:element-attr)) then
            safe-QName(($scope/search:attr-namespace)[1], ($scope/search:attr-local-name)[1])
        else ()
    let $do-count as xs:boolean := get-do-count($facet-def/@do-count)
    
    return
    <search:facet>
        {$facet-def}
        {
            (: Note that because date ranges can't be constructed into cts:query elements, if the search
            has a date filter applied, element-values will return false positives. :)
            let $base-search-criteria := transform-value-facet-query($search-criteria, $scope, ())
            let $base-query := build-cts-query($base-search-criteria)
            let $base-element :=
                let $count := search-estimate($base-search-criteria)
                return if ($do-count) then <search:all count="{$count}"/> else ()
            let $value-elements :=
                let $top as xs:integer? := $facet-def/search:value-facet/search:top/text()
                let $options := ("document")
                let $options :=
                    if ($CONFIG/cfg:search/cfg:collation) then
                        ($options, fn:concat("collation=",$CONFIG/cfg:search/cfg:collation))
                    else $options
                let $options :=
                    if ($do-count) then
                        ($options, "frequency-order")
                    else $options
                let $values :=
                    if ($element-attr-qname) then
                        cts:element-attribute-values($element-qname, $element-attr-qname, "", $options, $base-query)
                    else
                        cts:element-values($element-qname, "", $options, $base-query)
                let $values :=
                    if ($top and $do-count) then
                        $values[1 to $top]
                    else
                        $values
    	        for $value in $values
    	        let $count :=
        			if ($do-count) then
            			cts:frequency($value)
            	    else ()
    	        return
    		        if ($value and (fn:not($do-count) or ($do-count and $count > 0))) then
    		        <search:item value="{$value}">
    		        {if ($do-count) then attribute count {$count} else ()} 
    		        {$value}
    		        </search:item>
    		        else ()
            return
    	        (
    	        $base-element,
    	        $value-elements
    	        )
        }
   </search:facet>
}

(:~
:
: Transforms a base search:search-criteria element into a query with the
: specified scope set to the new value.
:
: @param $search-criteria A search:search-criteria element representing the base search.
: @param $scope The affected facet scope.
: @return A transformed search:search-criteria element that defines the new search.
:)
define function transform-value-facet-query(
	$search-criteria as element(search:search-criteria),
	$scope as element(),
	$new-value as xs:string?
) as element(search:search-criteria)
{
	let $new-values := (
		if ($scope instance of element(search:element-attr)) then
    		$search-criteria/search:values[fn:not(
    		    (./search:element-attr/search:local-name)[1] = $scope/search:local-name and
    		    ((./search:element-attr/search:namespace)[1] = $scope/search:namespace or
    		    (fn:empty(./search:element-attr/search:namespace/text()) and fn:empty($scope/search:namespace/text()))) and
    		    (./search:element-attr/search:attr-local-name)[1] = $scope/search:attr-local-name and
    		    ((./search:element-attr/search:attr-namespace)[1] = $scope/search:attr-namespace or
    		    (fn:empty(./search:element-attr/search:attr-namespace/text()) and fn:empty($scope/search:attr-namespace/text())))) ]
	    else
	    	$search-criteria/search:values[fn:not(
	    	    (./search:element/search:local-name)[1] = $scope/search:local-name and
	    	    ((./search:element/search:namespace)[1] = $scope/search:namespace or
    		    (fn:empty(./search:element/search:namespace/text()) and fn:empty($scope/search:namespace/text())))) ]
	    	,
		if ($new-value) then
			<search:values>
				{$scope}
				<search:value>{$new-value}</search:value>
			</search:values>
		else ()
		)
	return
	<search:search-criteria>
		{$search-criteria/@*}
		{$search-criteria/*[fn:local-name(.) ne "values"]}
		{$new-values}
	</search:search-criteria>
}

(:-- Collection Facet Methods --:)

(:~
:
: Resolves the requested collection facet for the passed search. Resolution involves determining the in-scope values, then
: counting the instances of those values within the search results.
:
: @param $search-criteria A search:search-criteria element representing the search.
: @param $facet-def The collection facet to resolve
: @return A fully resolved collection facet.
:)
define function resolve-collection-set-facet(
	$search-criteria as element(search:search-criteria),
	$facet-def as element(search:facet-def)
) as element(search:facet)
{
	let $coll-set-cfg := get-collection-set(($facet-def/search:collection-set-facet/search:set-id)[1])
	let $do-count as xs:boolean := get-do-count($facet-def/@do-count)

	return
	<search:facet>
	    {$facet-def}
        {
            (: Note that because date ranges can't be constructed into cts:query elements, if the search
            has a date filter applied, element-values will return false positives. :)
            let $base-search-criteria := transform-collection-set-facet-query($search-criteria, fn:string($coll-set-cfg/@id), ())
            let $base-query := build-cts-query($base-search-criteria)
            let $base-element :=
                let $count := search-estimate($base-search-criteria)
                return if ($do-count) then <search:all count="{$count}"/> else ()
            let $value-elements :=
                let $top as xs:integer? := $facet-def/search:collection-set-facet/search:top/text()
                let $options :=
                    if ($do-count) then
                        ("frequency-order", "document")
                    else ("document")
                let $values := cts:collection-match(fn:concat(fn:string($coll-set-cfg/cfg:base-uri), "*"),$options,$base-query)
                let $values :=
                    if ($top and $do-count) then
                        $values[1 to $top]
                    else
                        $values
    	        for $value in $values
                let $suffix := fn:substring-after($value, fn:string($coll-set-cfg/cfg:base-uri))
                let $count :=
        			if ($do-count) then
            			cts:frequency($value)
            	    else ()
    	        return
    		        if ($value and (fn:not($do-count) or ($do-count and $count > 0))) then
    		        <search:item value="{$suffix}">
    		        {if ($do-count) then attribute count {$count} else ()} 
    		        {$suffix}
    		        </search:item>
    		        else ()
            return
    	        (
    	        $base-element,
    	        $value-elements
    	        (:if ($do-count) then
        	        for $value-element in $value-elements
        	        order by xs:integer($value-element/@count) descending
        	        return $value-element
        	    else $value-elements:)
    	        )
        }
   </search:facet>
}

(:~
:
: Transforms a base search:search-criteria element into a query with the
: specified collection set to the new value.
:
: @param $search-criteria A search:search-criteria element representing the base search.
: @param $collection-set-id The id of the facet's collection set.
: @return A transformed search:search-criteria element that defines the new search.
:)
define function transform-collection-set-facet-query(
	$search-criteria as element(search:search-criteria),
	$collection-set-id as xs:string,
	$new-value as xs:string?
) as element(search:search-criteria)
{
	let $new-coll-values := 
	    (
	    $search-criteria/search:collections[fn:not(search:set-id = $collection-set-id)],
	    if ($new-value) then
	        <search:collections>
	            <search:set-id>{$collection-set-id}</search:set-id>
	            <search:value>{$new-value}</search:value>
	        </search:collections>
	    else ()
	    )
	return
	<search:search-criteria>
		{$search-criteria/@*}
		{$search-criteria/*[fn:local-name(.) ne "collections"]}
		{$new-coll-values}
	</search:search-criteria>
}

(:-- Date Group Facet Methods --:)

(:~
:
: Resolves the requested date-group facet for the passed search. Resolution involves determining the in-scope values, then
: counting the instances of those values within the search results.
:
: @param $search-criteria A search:search-criteria element representing the search.
: @param $facet-def The date-group facet to resolve
: @return A fully resolved date-group facet.
:)
define function resolve-date-group-facet(
	$search-criteria as element(search:search-criteria),
	$facet-def as element(search:facet-def)
) as element(search:facet)?
{
    (: Tests to ensure the database is properly configured for date group facets :)
    let $test := fn:true()
    (: test year configuration :)
    let $test := $test and fn:boolean(fn:string($CONFIG/cfg:collection-sets/cfg:collection-set[@id = "year"]/cfg:base-uri))
    (: test year-month configuration :)
    let $test := $test and fn:boolean(fn:string($CONFIG/cfg:collection-sets/cfg:collection-set[@id = "year-month"]/cfg:base-uri))
    (: test day configuration :)
    let $test := $test and fn:exists(($CONFIG/cfg:facets/cfg:day-group-field/(search:element|search:element-attr|search:scope-id))[1])
    let $test := if (fn:not($test)) then fn:error("The database is not currently configured for date group facets") else ()

    let $date-group := fn:lower-case(fn:string($facet-def/search:date-group-facet))
    let $day-field := resolve(($CONFIG/cfg:facets/cfg:day-group-field/(search:element|search:element-attr|search:scope-id))[1])

    let $facet :=
        if ($date-group = "year") then
            let $date-facet-def :=
                <search:facet-def>
                    {$facet-def/@*}
                    <search:collection-set-facet>
                        <search:set-id>year</search:set-id>
                    </search:collection-set-facet>
                </search:facet-def>
            let $modified-queryOptions := $search-criteria
            let $modified-queryOptions := transform-collection-set-facet-query($modified-queryOptions, "year-month", ())
            let $modified-queryOptions := transform-value-facet-query($modified-queryOptions, $day-field, ())
            return resolve-facet($modified-queryOptions, $date-facet-def)
        else if ($date-group = "month") then
            let $date-facet-def :=
                <search:facet-def>
                    {$facet-def/@*}
                    <search:collection-set-facet>
                        <search:set-id>year-month</search:set-id>
                    </search:collection-set-facet>
                </search:facet-def>
            let $modified-queryOptions := $search-criteria
            let $modified-queryOptions := transform-value-facet-query($modified-queryOptions, $day-field, ())
            return resolve-facet($modified-queryOptions, $date-facet-def)
        else if ($date-group = "day") then
            let $date-facet-def :=
                <search:facet-def>
                    {$facet-def/@*}
                    <search:value-facet>
                    {$day-field}
                    </search:value-facet>
                </search:facet-def>
            let $modified-queryOptions := $search-criteria
            return resolve-facet($modified-queryOptions, $date-facet-def)
        else ()
    return
        if ($facet) then
            element search:facet {
                (
                $facet-def,
                $facet/search:facet-def,
                $facet/*[fn:not(fn:local-name(.) = ("facet-def", "item"))],
                for $item in $facet/search:item
                order by $item/@value
                return $item
                )
            }
        else ()
}

(:-- Trailing Date Facet Methods --:)

(:~
:
: Resolves the requested trailing date facet for the passed search. Resolution involves determining the
: in-scope values, then counting the instances of those values within the search results.
:
: @param $search-criteria A search:search-criteria element representing the search.
: @param $facet-def The trailing date facet to resolve
: @return A fully resolved trailing date facet.
:)
 define function resolve-trailing-date-facet(
	$search-criteria as element(search:search-criteria),
	$facet-def as element(search:facet-def)
) as element(search:facet)?
{
	let $facet-content := $facet-def/search:trailing-date-facet[1]
	let $base-date := 
		try {
		    xs:date($facet-content/search:base-date[1])
		} catch($exp) {
			fn:current-date()
		}
	let $date-format := $facet-content/search:date-format
    let $trailing-duration := 
		for $i in $facet-content/search:trailing-duration
		return 
    		try { 
    		    xdt:dayTimeDuration($i) 
    		} catch ($exp) {()}
	let $do-count as xs:boolean := get-do-count($facet-def/@do-count)

	return
	    <search:facet>
	    <search:base-date>{$base-date}</search:base-date>
	    {$facet-def}
        { if ($trailing-duration) then
            (: Note that because date ranges can't be constructed into cts:query elements, if the search
            has a date filter applied, element-values will return false positives. :)
            let $base-search-criteria := transform-trailing-date-facet-query($search-criteria, (), ())
            let $base-query := build-cts-query($base-search-criteria)
            let $base-element :=
                let $count := search-estimate($base-search-criteria)
                return if ($do-count) then <search:all count="{$count}"/> else ()
            let $value-elements :=
    	        for $value at $pos in $trailing-duration
    	        let $fcount :=
        			if ($do-count) then
            			let $newQueryOptions := transform-trailing-date-facet-query($search-criteria, $base-date, $value)
            	        return search-estimate($newQueryOptions)
            	    else ()
            	let $date-value := xs:date(if ($value) then $base-date - $value  else  $value)
            	let $date-time-value := parse-to-dateTime($date-value, xs:time("00:00:00"))
    	        return
    		        <search:item value="{$value}">
    		        {if ($do-count) then attribute count {$fcount} else ()}
    		        {
    		        if ($facet-content/search:trailing-duration[$pos]/@desc) then
    		            fn:string($facet-content/search:trailing-duration[$pos]/@desc)
    		        else if ($date-format) then
						xdmp:strftime($date-format,$date-time-value)
				    else
						$date-value
                    }
    		        </search:item>
            return
    	        (
    	        $base-element,
    	        $value-elements
    	        )
    	else ()
        }
   </search:facet>
}

(:~
:
: Transforms a base search:search-criteria element into a query with the
: specified date range set to the new value.
:
: @param $search-criteria A search:search-criteria element representing the base search.
: @param $base-date The starting date of the duration.
: @param $new-value The value of the duration.
: @return A transformed search:search-criteria element that defines the new search.
:)
define function transform-trailing-date-facet-query(
	$search-criteria as element(search:search-criteria),
	$base-date as xs:date?,
	$new-value as xdt:dayTimeDuration?
) as element(search:search-criteria)
{
	let $new-values := (
		if ($new-value) then
			<search:date-range>
				{if ($base-date) then <search:base-date>{$base-date}</search:base-date> else ()} 
				<search:trailing-duration>{$new-value}</search:trailing-duration>
			</search:date-range>
		else ()
		)
	return
	<search:search-criteria>
		{$search-criteria/@*}
		{$search-criteria/*[fn:local-name(.) ne "date-range"]}
		{if ($new-values) then
			$new-values
		else ()
		}
	</search:search-criteria>
}

(:~
:
: Resolves the values in a facet into names using a value file located in the database.
:
: @param $facet A facet that has been resolved from it's definition.
: @return The facet with the values resolved to names.
:)
define function parse-to-dateTime($date as xs:date, $time as xs:time) as xs:dateTime
{
	let $date-sequence := fn:tokenize(fn:string($date), "-") 
	let $count :=  fn:count($date-sequence)
	let $date-part := 
		if($count eq 3) then (:Only a date:)
			fn:string-join($date-sequence,"-")
		else if($count eq 4) then (:Contains  a  UTC:)
			fn:string-join(fn:subsequence($date-sequence,1,3),"-")   
		else
		   fn:error("Bad Function Implementation")
	let $utc-part := if($count eq 4) then fn:subsequence($date-sequence,4) else ()
	let $utc-part := if($utc-part) then fn:concat("-",$utc-part) else ()
	return
	     xs:dateTime(fn:concat($date-part,"T",fn:string($time),$utc-part))
}

(:-- Facet Value Methods --:)

(:~
:
: Resolves the values in a facet into names using a value file located in the database.
:
: @param $facet A facet that has been resolved from it's definition.
: @return The facet with the values resolved to names.
:)
define function resolve-facet-values($facet as element(search:facet)) as element(search:facet)
{
    let $name-lookup-id := fn:string(($facet/search:facet-def/*/search:name-lookup-id)[1])
    let $lookup-doc := get-name-lookup-file($name-lookup-id)
    let $values :=
      for $x in $facet/search:item
      let $name := fn:string($lookup-doc/lkup:lookup/lkup:item[@value eq $x/@value]/@name)
      let $name := if ($name) then $name else fn:string($x/@value)
      return <search:item>{$x/@*, $name}</search:item>
    return
        if ($lookup-doc) then
           <search:facet>{
           $facet/*[fn:local-name(.) ne "item"],
           $values
            }</search:facet>
        else
            $facet (: return as is :)
}

(:~
:
: Returns a facet value file based on the set name.
:
: @param $name-lookup-id The value set to retreive from the server.
: @return The facet value file, if found.
:)
define function get-name-lookup-file($name-lookup-id as xs:string?) as document-node()?
{
    if ($name-lookup-id) then
        let $name-lookup-directory := fn:string($CONFIG/cfg:facets/cfg:name-lookup-directory)
        let $doc := fn:doc(fn:concat($name-lookup-directory, $name-lookup-id, ".xml"))
        return
            if ($doc) then
                $doc
            else
                fn:error(fn:concat("The name lookup file for ID '", $name-lookup-id,"' could not be found"))
    else ()
}

(:~
:
: Get's the @do-count from the passed item.
:
: @param $setting The item, attribute, or string containing the do-count value.
: @return The boolean value of do-count
:)
define function get-do-count($setting as item()?) as xs:boolean
{
    try {
        xs:boolean(fn:string($setting))
    } catch ($exp) {
        let $config := fn:string($CONFIG/cfg:facets/cfg:default-do-count)
        return
            if ($config) then
                try {
                    xs:boolean($config)
                } catch ($exp) {
                    fn:false()
                }
            else fn:false()
    }
}

(:-- ID Resolution Methods --:)

(:~
:
: Recursively resolves scope and facet ID references in an element.
:
: @param $nodes The nodes to be resolved.
: @return The resolved node.
:)
define function resolve($nodes as node()*) as node()*
{
	for $x in $nodes return
	if (fn:empty($x)) then () else
	typeswitch ($x)
	case element(search:scope-id) return resolve-scope-id($x)
	case element(search:facet-def-id) return resolve-facet-def-id($x)
	case element() return resolve-asis($x)
	default return $x
}

(:~
:
: Recursively resolves the child nodes of an element.
:
: @param $x The element to be resolved.
: @return The resolved element.
:)
define function resolve-passthru($x as element()) as node()*
{
    for $z in $x/node() return resolve($z)
}

(:~
:
: Returns an element as-is, and resolves the child nodes of the element.
:
: @param $x The element to be resolved.
: @return The resolved element.
:)
define function resolve-asis($x as element()) as element()
{
    element
      {fn:node-name($x)}
    {
      $x/attribute::*,
      resolve-passthru($x)
    }
}

(:~
:
: Resolves a scope-id into a search:element, search:element-attr or search:field, and continues to recursively resolve inside.
:
: @param $x The scope-id to be resolved.
: @return The resolved element.
:)
define function resolve-scope-id($x as element(search:scope-id)) as element()
{
    if (fn:string($x)) then
        let $scope-id := fn:string($x)
        let $scope := $CONFIG/cfg:scope/(search:element|search:element-attr)[@id = $scope-id]
        return
            if ($scope) then
                resolve($scope)
            else
                fn:error(fn:concat("Scope ID '", $scope-id, "' could not be resolved"))
    else
        $x
}

(:~
:
: Resolves a facet-def-id into a facet-def element, and recursively resolves inside of the facet-def.
:
: @param $x The facet-def-id element to be resolved.
: @return The resolved element.
:)
define function resolve-facet-def-id($x as element(search:facet-def-id)) as element()
{
    if (fn:string($x)) then
        let $facet-def-id := fn:string($x)
        let $facet-def := $CONFIG/cfg:facets/search:*[@id = $facet-def-id]
        return
            if ($facet-def) then
                resolve($facet-def)
            else
                fn:error(fn:concat("Facet Def ID '", $facet-def-id, "' could not be resolved"))
    else
        $x
}
