module "http://www.marklogic.com/ps/versi/display"

import module namespace search="http://www.marklogic.com/ps/lib/lib-search" at "lib-search.xqy"
import module "http://www.marklogic.com/ps/lib/lib-search" at "lib-search-custom.xqy"
import module namespace uit="http://www.marklogic.com/ps/lib/lib-uitools" at "lib-uitools.xqy"
import module namespace sdis="http://www.marklogic.com/ps/versi/search-ui" at "search-ui.xqy"

declare namespace htm = "http://www.w3.org/1999/xhtml"
declare namespace qm = "http://marklogic.com/xdmp/query-meters"
declare namespace tm = "http://www.temis.com/annotations/1.1/"
declare namespace cfg = "http://www.marklogic.com/ps/lib/lib-search/config"

define variable $SITE-TITLE as xs:string { "Rapid Prototype Demo" }
define variable $ITEMS-PER-PAGE as xs:integer { 8 }

define variable $LIB-SEARCH-CONFIG as element(cfg:config) {
    <config
    	xmlns="http://www.marklogic.com/ps/lib/lib-search/config"
    	xmlns:search="http://www.marklogic.com/ps/lib/lib-search"
    	xmlns:lp="http://www.marklogic.com/ps/lib/lib-parser">
    	<search>
    		<base-criteria>
    			<search:directories depth="1">
    				<search:directory>/content/</search:directory>
    			</search:directories>
    		</base-criteria>
    		<sort-fields>
    			<sort-field id="date" type="xs:dateTime" direction="descending">doc/metadata/date</sort-field>
    		</sort-fields>
    		<namespaces>
    			<namespace prefix="tm">http://www.temis.com/annotations/1.1/</namespace>
    		</namespaces>
    		<lp:search-field-map>
    			<lp:mapping code="title"><tm:zone value="title" xmlns:tm="tm"/></lp:mapping>
    		</lp:search-field-map>
    		<collation>http://marklogic.com/collation/</collation>
    	</search>
    	<facets>
    		<default-do-count>true</default-do-count>
    	</facets>
    	<scope>
    		<search:element id="title">
    			<search:local-name>title</search:local-name>
    		</search:element>
    		<search:element-attr id="person">
    			<search:namespace>http://www.temis.com/annotations/1.1/</search:namespace>
    			<search:local-name>person</search:local-name>
    			<search:attr-local-name>value</search:attr-local-name>
    		</search:element-attr>
    		<search:element-attr id="comp">
    			<search:namespace>http://www.temis.com/annotations/1.1/</search:namespace>
    			<search:local-name>company</search:local-name>
    			<search:attr-local-name>value</search:attr-local-name>
    		</search:element-attr>
    		<search:element-attr id="ctry">
    			<search:namespace>http://www.temis.com/annotations/1.1/</search:namespace>
    			<search:local-name>country</search:local-name>
    			<search:attr-local-name>location_country</search:attr-local-name>
    		</search:element-attr>
    		<search:element-attr id="org">
    			<search:namespace>http://www.temis.com/annotations/1.1/</search:namespace>
    			<search:local-name>organisation</search:local-name>
    			<search:attr-local-name>value</search:attr-local-name>
    		</search:element-attr>
    		<search:element-attr id="tckr">
    			<search:local-name>quote</search:local-name>
    			<search:attr-local-name>symbol</search:attr-local-name>
    		</search:element-attr>
    	</scope>
    	<debug>true</debug>
    </config>
}

define variable $FACETS as element(search:facet-defs)? {
    <facet-defs xmlns="http://www.marklogic.com/ps/lib/lib-search">
          <facet-def>
            <value-facet>
        		<scope-id>comp</scope-id>
                <top>50</top>
            </value-facet>
            <custom>
                <sort>name-asc</sort>
                <qs-id>comp</qs-id>
                <title>Companies</title>
                <icon>images/silk/building.png</icon>
            </custom>
         </facet-def>
    </facet-defs>
}

define variable $CLOUD as element(search:facet-defs)? {
    <facet-defs xmlns="http://www.marklogic.com/ps/lib/lib-search">
         <facet-def>
            <value-facet>
        	    <scope-id>ctry</scope-id>
                <top>10</top>
            </value-facet>
            <custom>
                <sort>name-asc</sort>
                <qs-id>ctry</qs-id>
                <title>Countries</title>
                <icon>images/silk/world.png</icon>
            </custom>
        </facet-def>
          <facet-def>
            <value-facet>
        		<scope-id>tckr</scope-id>
                <top>10</top>
            </value-facet>
            <custom>
                <sort>name-asc</sort>
                <qs-id>tckr</qs-id>
                <title>Stocks</title>
                <icon>images/silk/coins.png</icon>
            </custom>
         </facet-def>
         <facet-def>
            <value-facet>
        		<scope-id>org</scope-id>
                <top>10</top>
            </value-facet>
            <custom>
                <sort>name-asc</sort>
                <qs-id>org</qs-id>
                <title>Organizations</title>
                <icon>images/silk/group.png</icon>
            </custom>
        </facet-def>
         <facet-def>
            <value-facet>
        		<scope-id>person</scope-id>
                <top>10</top>
            </value-facet>
            <custom>
                <sort>name-asc</sort>
                <qs-id>person</qs-id>
                <title>People</title>
                <icon>images/silk/user_suit.png</icon>
            </custom>
        </facet-def>
    </facet-defs>        
}

(: Search Result functions :)

define function search-results($params as element(params)) as element()*
{
	let $page := if (($params/p) and fn:not(fn:empty($params/p))) then xs:integer($params/p) else 1
	let $items-per-page := if ($params/i) then xs:integer($params/i) else $ITEMS-PER-PAGE
	let $start := (($page - 1) * $items-per-page) + 1
	let $end := $page * $items-per-page
	
	let $query := sdis:params-to-query($params) 
	let $start-time := xdmp:query-meters()/qm:elapsed-time
	let $results := search:search-results($query, xs:integer($start), xs:integer($end))
	let $end-time := xdmp:query-meters()/qm:elapsed-time
	let $count as xs:integer := search:search-count($query)
	let $page-info := uit:page-info($page, $items-per-page, $count)
	return
		<div class="search_results"> {
			if ($results) then
			    (
			        sdis:query-description($params),
    			    sdis:results-info($params, $end-time - $start-time, $page-info),
    			    for $result at $pos in $results
    			    return search-result($result, ($start - 1 + $pos), $params, $query),
    			    sdis:pagination($params, $page-info)
				)
			else
				<p style="font-size:120%">No results found. Please <a href="search.xqy?{uit:build-querystring($params, ())}">try your search again</a></p>
		} </div>
}

define function search-result(
    $result as node(),
    $position as xs:integer,
    $params as element(params),
    $query as element(search:search-criteria)
    ) as element()
{
	let $uri := xdmp:node-uri($result)
    let $highlight := sdis:highlight($result, $query)
	let $title :=
	    if ($highlight) then
	        $highlight/doc/title/node()
	    else
	        $result/doc/title/node()
	let $date := format-result-date($result/doc/metadata/date)
    return
		<div id="result_{$uri}">
			{if ($position mod 2 = 0) then attribute class {"result alt"} else attribute class {"result"}}
			<div class="header">
				<a href="get-file.xqy?uri={$uri}"><img class="icon" title="View Article" src="images/silk/page.png"/>{" ", $title }</a>
			</div>
			<div class="summary"><strong>Published:</strong> {" ", $date}</div>
			{sdis:create-summary($result, $highlight, $result//html/body/p[1 to 2], fn:true())}
		</div>
}

define function format-result-date($date-node as node())
{
    if ($date-node castable as xs:dateTime) then
        xdmp:strftime("%A, %B %d, %Y",xs:dateTime($date-node))
    else if (fn:string($date-node)) then
        fn:string($date-node)
    else
        "Not Available"
}

(: Facet Functions :)

define function search-facets($params as element()) as element()?
{
    sdis:search-facets($params, $FACETS)
}

define function search-results-analysis($params as element(params)) as element()*
{
    sdis:search-results-analysis($params, $CLOUD)
}