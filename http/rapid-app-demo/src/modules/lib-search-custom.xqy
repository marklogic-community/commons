(:~ 
: This module contains all custom code required for searching the repository
: @author Mark Logic
: @version 1.0.2
:)
module "http://www.marklogic.com/ps/lib/lib-search"

import module namespace search="http://www.marklogic.com/ps/lib/lib-search" at "lib-search.xqy"
import module namespace dis="http://www.marklogic.com/ps/versi/display" at "display-demo.xqy"

declare namespace cfg = "http://www.marklogic.com/ps/lib/lib-search/config"

define variable $CONFIG as element(cfg:config) {$dis:LIB-SEARCH-CONFIG}

(:~ 
: 
: A user-defined processing function used by search-summary(). If you decide to use
: search-summary() instead of search-results() you'll need to customize this function
: to determine what the content of each search result will be.
:
: @param $results A sequence of result nodes
: @param $search-criteria The search-criteria element for the current search.
: @param $query The parsed cts:query value for the current search (useful for highlighting).
: @return The processed version of each node.
:)
define function process-search-results(
    $results as node()*,
    $search-criteria as element(search:search-criteria),
    $query as cts:query?
) as element()*
{
    let $last-time := xdt:dayTimeDuration(xdmp:query-meters()/*[1])  
    
    for $result in $results
    
    let $time := xdt:dayTimeDuration(xdmp:query-meters()/*[1])
    let $duration := $time - $last-time
    let $time := xdmp:set($last-time, $time)
    
    return
        <search:result>
        <search:score>{cts:score($result)}</search:score>
        <search:document-uri>{xdmp:node-uri($result)}</search:document-uri>
        <search:processing-time>{$duration}</search:processing-time>
        </search:result>
}

(:-- User Defined Functions Below --:)

(: This is disabled until further notice
define function do-summarize($result as node()*, $query as cts:query?)
{
    (: Make sure you have the document element, and not the document-node. Note that text documents do
       not have a root element, so summarizing will be disabled. :)
    let $result-element :=
        typeswitch($result)
        case document-node() return $result/*
        case element() return $result
        default return ()
    return
        if ($result-element instance of element() and fn:exists($query)) then
            summarize-result($result-element, $query)
        else ()

}:)