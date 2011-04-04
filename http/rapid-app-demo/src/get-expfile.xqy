(:
 : Provides basic caching to resource files such as images and stylesheets because
 : Mark Logic doesn't support it prior to 3.2-2. Use this file for requests of all images
 : JavaScript, and CSS files if you are using a version prior to 3.2-2.
 :)
 
declare namespace http="xdmp:http"
let $expires := xdmp:get-request-field("ex","1")
let $path := xdmp:url-decode(xdmp:get-request-field("uri",""))
let $host := xdmp:get-request-header("host")
let $headers :=
	<headers xmlns="xdmp:http">
	{ for $i in xdmp:get-request-header-names() return element {$i} {xdmp:get-request-header($i)} }
	</headers>

let $new-response := xdmp:http-get(fn:concat("http://",$host,$path),<options xmlns="xdmp:http">{$headers}</options>)

let $content-type := fn:tokenize(fn:string($new-response[1]/*:headers/*:content-type), ";")[1] 

return

(
for $i in $new-response[1]/http:response/* return xdmp:add-response-header(fn:local-name($i),fn:data($i))
,
xdmp:add-response-header("Expires", xdmp:strftime("%a, %d %b %Y %H:%M:%S",fn:current-dateTime() + xdt:dayTimeDuration(fn:concat("P1DT",$expires,"H"))))
,
xdmp:set-response-content-type($content-type)
,
$new-response[2]
)
