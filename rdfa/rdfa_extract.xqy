xquery version "1.0-ml";

(: Copyright 2002-2008 Mark Logic Corporation.  All Rights Reserved. :)

import module namespace rdfa = "http://marklogic.com/ns/rdfa-impl#" at "rdfa.xqy";

declare variable $url := xdmp:get-request-field('url');

let $doc := xdmp:document-get($url,
       <options xmlns="xdmp:document-get">
           <format>xml</format>
           <repair>full</repair>
       </options>)
return (
xdmp:add-response-header("Content-type", "application/rdf+xml"),
rdfa:parse_rdfa($doc, $url)
)