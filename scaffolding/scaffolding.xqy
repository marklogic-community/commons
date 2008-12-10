xquery version "0.9-ml"

define variable $empty-elt-size as xs:integer { 30 }
define variable $max-elt-size as xs:integer { 30 }

define variable $empty-att-size as xs:integer { 15 }
define variable $max-att-size as xs:integer { 30 }

(:~
: The main html page which wraps all other pages (display-home, display-dir, 
: display-file).
:
: @param $title The page title.
: @param $content The content to wrap.
:)
define function display($title as xs:string?, $content as item())
{
	let $content-type := xdmp:set-response-content-type("text/html")
	let $doc-type := '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">'
	return
		($doc-type,
		<html>
			<head>
				<title>{ if ($title) then concat($title, ' - ') else () }Scaffolding</title>
				<style type="text/css">
				<!--
					body, input { font-family: 'courier new'; font-size: 14px; }
					div.element-contents ul li { list-style: none; }
					.sub { font-size: 12px; }
					span.elt { color: blue; }
					span.att { color: red; }
				-->
				</style>
			</head>
			<body>
				<h2><a href="{ self() }">Scaffolding</a></h2>
				{ $content }
			</body>
		</html>)
}

(:~
: Displays the main home screen, including a few examples and warnings.
:)
define function display-home()
{
	display((),
		<div>
			<form action="?" method="get">
				Absolute uri (file or directory):<br />
				<input type="text" name="uri" value="" size="40" />
				<input type="submit" value="View / Edit" />
			</form>
			<p>
				Or manually edit the query string:<br />
				<b>{ self() }?uri=/path/to/dir/</b> to list a directory<br />
				<b>{ self() }?uri=/path/to/file.xml</b> to view/edit a file
			</p>
			<p>
				<b>Warning:</b> This script can make modifications to the contents of your MarkLogic 
				database.  <b>USE AT YOUR OWN RISK</b>.  Do not make this file accessible in a production
				environment.
			</p>
			<p>
				<b>Warning:</b> The uri <b>{ self() }?uri=/</b> will happily go about listing your entire
				database.  You probably don't want this.
			</p>
			<p>
				<b>Warning/Todo:</b> This script currently ignores &quot;marked up&quot; data, that is,
				element nodes mixed with text nodes. For example, <b>&lt;container&gt;&lt;i&gt;here&lt;/i&gt; 
				is some &lt;b&gt;marked up&lt;/b&gt; text&lt;/container&gt;</b> will be displayed (and saved) as
				<b>&lt;container&gt;here is some marked up text&lt;/container&gt;</b>.
			</p>
			<p>
				<b>Warning/Todo:</b> This script currently ignores namespaces.
			</p>
		</div>
	)
}

(:~
: Displays a recursive listing of all files rooted at a directory. Note that
: passing a parameter of '/' will happy display every file in the the entire 
: database, which is probably not desireable.
:
: @param The directory to display.
:)
define function display-dir($uri as xs:string)
{
	display($uri,
		let $uri-with-slash := if (ends-with($uri, '/')) then $uri else concat($uri, '/')
		let $files := for $file in xdmp:directory($uri-with-slash, 'infinity') return base-uri($file)
		return
			if (not(exists($files))) then
				<p>resource empty or not found: <b>{ $uri }</b></p>
			else
				<div>
					<p><b>{ display-path($uri-with-slash) }</b></p>
					<ul>{
						for $file in $files
						order by $file
						return
							<li><a href="?uri={ $file }">{ $file }</a></li>
					}</ul>
				</div>
	)
}

(:~
: Displays a file.
:
: @param The directory to display.
:)
define function display-file($uri as xs:string)
{
	display($uri,
		if (not(doc-available($uri))) then
			<p>file not found: <b>{ $uri }</b></p>
		else
			<div>
				<form action="?uri={ $uri }&save=true" method="post">
					<p><input type="submit" value="Save" />&nbsp;<b>{ display-path($uri) }</b></p>
					<div class="element-contents">{ display-element-contents(doc($uri)/element()) }</div>
					<p><input type="submit" value="Save" /></p>
				</form>
			</div>
	)
}

(:~
: The meat and potatoes of Scaffolding. Recurively walks an xml structure,
: displaying its elements and attributes in html with appropriate inputs.
:
: $param $elements A seq of elements, usually starting at doc($uri)/element()
:)
define function display-element-contents($elements as element()*)
{
	for $elt in $elements
	return
		<ul>
			<li>{
				open-tag($elt),
				if (exists($elt/text()) or not(exists($elt/element()))) then
					let $text := string($elt)
					return
						if (string-length($text) gt $max-elt-size) then
							<textarea name="__element__{ xdmp:path($elt) }" rows="3" cols="30">{ $text }</textarea>
						else
							<input type="text" name="__element__{ xdmp:path($elt) }" value="{ $text }"
								size="{ if ($text) then string-length($text) + 1 else $empty-elt-size }" />
				else
					display-element-contents($elt/element()),
				close-tag($elt),
				if (not($elt eq root($elt))) then add-remove-links($elt) else ()
			}</li>
		</ul>
}

(:~
: Generates an html-friendly visual representation of an xml element opening
: tag, including attributes.
:
: @param $elt The element to represent.
:)
define function open-tag($elt as element())
as element(span)
{
	<span class="elt">{
		if (not($elt/@*)) then
			concat('&lt;', node-name($elt), '&gt; ')
		else (
			concat('&lt;', node-name($elt)),
			for $att in $elt/@*
			let $text := string($att)
			return (
				<span class="att">{
					concat(' ', node-name($att), '=')
				}</span>,
				<input type="text" name="__attribute__{ xdmp:path($att) }" value="{ $text }" 
					size="{ min(($max-att-size, if ($text) then string-length($text) + 1 else $empty-att-size)) }" />
			),
			'&gt; '
		)
	}</span>
}

(:~
: Generates an html-friendly visual representation of an xml element closing
: tag.
:
: @param $elt The element to represent.
:)
define function close-tag($elt as element())
as element(span)
{
	<span class="elt">{
		concat(' &lt;/', node-name($elt), '&gt;')
	}</span>
}

(:~
: Provides a couple of lines to duplicate or remove elements.
:
: @param $elt The element to create the links for.
:)
define function add-remove-links($elt as element())
{
	<span class="sub">
		(<a href="?uri={ base-uri($elt) }&insert={ xdmp:path($elt) }" title="insert">+</a>
		/
		<a href="?uri={ base-uri($elt) }&remove={ xdmp:path($elt) }" title="remove">-</a>)
	</span>
}

(:~
: Duplicates an xml element, and inserts it as the sibling of the original.
:
: @param $uri The uri of the document.
: @param $insert-path The remaining xpath to the element we wish to duplicate.
:)
define function insert-duplicate-sibling($uri as xs:string, $insert-path as xs:string)
{
	let $node := concat("(doc('", $uri, "')", $insert-path, ')[last()]')
	return
		xdmp:eval(concat("xdmp:node-insert-after(", $node, ", ", $node, ")"))
}

(:~
: Duplicates an xml element, and inserts it as the sibling of the original.
:
: @param $uri The uri of the document.
: @param $insert-path The remaining xpath to the element we wish to duplicate.
:)
define function remove-element($uri as xs:string, $remove-path as xs:string)
{
	let $node := concat("(doc('", $uri, "')", $remove-path, ')[last()]')
	return
		xdmp:eval(concat("xdmp:node-delete(", $node, ")"))
}

(:~
: Given a path, generates a slash-delimited list of links to each token in the
: path. For example, a string such as "/path/to/file.xml" will be represented 
: by /<a href="/path">path</a>/<a href="/path/to">to</a>/<a href="/path/to/file.xml">file.xml</a>
:
: @param $path The path to represent.
:)
define function display-path($path as xs:string)
as element(span)
{
	<span>{
		let $link := tokenize($path, '/')[1]
		for $token in tokenize($path, '/')[2 to last()]
		return (
			xdmp:set($link, concat($link, '/', $token)),
			<span>/<a href="?uri={ $link }">{ $token }</a></span>
		)
	}</span>
}

(:~
: Saves all fields presented to the user in display-file($uri).
:
: @param $uri The uri of the file to modify.
: @param $fields The list of fields to save, elements prefixed with __element__
: 	and attributes prefixed with __attribute__.
:)
define function save-fields($uri as xs:string, $fields as xs:string*)
{
	for $path in $fields
	order by $path
	return (
		if (starts-with($path, '__element__')) then
			update-element($uri, substring-after($path, '__element__'), xdmp:get-request-field($path))
		else if (starts-with($path, '__attribute__')) then
			update-attribute($uri, substring-after($path, '__attribute__'), xdmp:get-request-field($path))
		else ()
	)
}

(:~
: Replaces all nodes contained by $path in $uri with the text node $value.
:
: @param $uri The uri of the file to modify.
: @param $path The xpath to the element to modify.
: @param $value The new text value.
:)
define function update-element($uri as xs:string, $path as xs:string, $value as xs:string)
{
	let $atts := 
		for $att in xdmp:eval(concat("doc('", $uri, "')", $path, '/@*'))
		return concat("attribute ", name($att), " { '", $att, "' }")
	let $atts := if ($atts) then concat(string-join($atts, ', '), ', ') else ()
	let $elt-name := tokenize(string-join(tokenize($path, "\[\d+\]"), ''), '/')[last()]
	let $old-node := concat("doc('", $uri, "')", $path)
	let $new-node := concat("element { '", $elt-name, "' } { ", $atts, " text { '", replace($value, "'", "''"), "' } }")
	return
		xdmp:eval(concat("xdmp:node-replace(", $old-node, ", ", $new-node, ")"))
}

(:~
: Replaces attribute $path in $uri with the text node $value.
:
: @param $uri The uri of the file to modify.
: @param $path The xpath to the attribute to modify 
: @param $value The new text value.
:)
define function update-attribute($uri as xs:string, $path as xs:string, $value as xs:string)
{
	let $old-node := concat("doc('", $uri, "')", $path)
	let $new-node := concat("attribute { '", substring-after($path, '@'), "' } { '", replace($value, "'", "''"), "' }")
	return
		xdmp:eval(concat("xdmp:node-replace(", $old-node, ", ", $new-node, ")"))
}

(:~
: The page currently being requested.  Eg. if the request address is
: http://www.domain.com/path/to/file.xqy?q=xquery&page=1, this function will
: return "file.xqy".
:
: @return The page currently being requested.
:)
define function self()
as xs:string
{
	tokenize(xdmp:get-request-path(), "/")[last()]
}

(: TAKE ACTION! :)

let $save := xdmp:get-request-field('save', '')
let $insert := xdmp:get-request-field('insert', '')
let $remove := xdmp:get-request-field('remove', '')
let $uri := xdmp:get-request-field('uri', '')
return
	if ($save) then (
		save-fields($uri, xdmp:get-request-field-names()),
		xdmp:redirect-response(xdmp:get-request-header('Referer'))
	)
	else if ($insert) then (
		insert-duplicate-sibling($uri, $insert),
		xdmp:redirect-response(xdmp:get-request-header('Referer'))
	)
	else if ($remove) then (
		remove-element($uri, $remove),
		xdmp:redirect-response(xdmp:get-request-header('Referer'))
	)
	else if (ends-with($uri, '.xml')) then (
		display-file($uri)
	)
	else if ($uri) then (
		display-dir($uri)
	)
	else (
		display-home()
	)