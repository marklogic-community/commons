(:
 : Provides access to files in the database. If the querystring contains download=true,
 : the file will be downloaded, else it will be displayed inline.
 :)

if (xdmp:get-request-field("uri", "") ne "") then
	let $uri := xdmp:get-request-field("uri", "")
	let $filename := fn:tokenize($uri, "/")[fn:last()]
	let $content-type := xdmp:uri-content-type($uri)
	let $download := xdmp:get-request-field("download","")
	let $document := fn:doc($uri)
	return
	(
	xdmp:set-response-content-type($content-type),
	if (fn:lower-case($download) = "true") then
		xdmp:add-response-header("Content-Disposition", fn:concat("attachment; filename=", $filename))
	else
		xdmp:add-response-header("Content-Disposition", fn:concat("inline; filename=", $filename)),
	$document
	)
else ()