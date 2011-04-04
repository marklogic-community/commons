import module namespace page="http://www.marklogic.com/ps/versi/page-layout" at "modules/page-layout-demo.xqy"
import module namespace dis="http://www.marklogic.com/ps/versi/display" at "modules/display-demo.xqy"
import module namespace sdis="http://www.marklogic.com/ps/versi/search-ui" at "modules/search-ui.xqy"
import module namespace uit="http://www.marklogic.com/ps/lib/lib-uitools" at "modules/lib-uitools.xqy"

declare namespace htm="http://www.w3.org/1999/xhtml"

let $params := (: Recommended that lib-uitools is used to generate params from request :)
    uit:load-params()
let $page-info :=
    page:build-page-info(
        fn:concat("Search Results - ", $dis:SITE-TITLE), (: title :)
    	<link rel="stylesheet" type="text/css" media="screen" href="css/appspecific-demo.css" />, (: head elements :)
    	() (: body.onload javascript :)
	)
	
let $search := (dis:search-results($params))
let $sidebar := (sdis:search-filter($params), sdis:sort($params), dis:search-facets($params))
let $content := (
    dis:search-results-analysis($params),    
    page:two-column( "sidebar", $search, $sidebar) )

return page:output($params, $page-info, $content)

