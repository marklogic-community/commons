xquery version "1.0"

(:
	The main html page which wraps all other pages (display-info, display-dir, display-file)
:)
define function display-page($title as xs:string?, $content as item())
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
					body { font-family: 'courier new'; font-size: 14px; }
					div.element-contents ul li { list-style: none; }
					.sub { font-size: 12px; }
				-->
				</style>
			</head>
			<body>
				<h2><a href="{ tokenize(xdmp:get-request-path(), "/")[last()] }">Scaffolding</a></h2>
				{ $content }
			</body>
		</html>)
}

define function display-info()
{
	display-page((),
		<div>
			<form action="?" method="get">
				Absolute uri (file or directory):<br />
				<input type="text" name="uri" value="" size="40" maxlength="128" />
				<input type="submit" value="View / Edit" />
			</form>
			<p>
				Or manually edit the query string:<br />
				<b>{ tokenize(xdmp:get-request-path(), "/")[last()] }?uri=/path/to/dir/</b> to list a directory<br />
				<b>{ tokenize(xdmp:get-request-path(), "/")[last()] }?uri=/path/to/file.xml</b> to view/edit a file
			</p>
			<p><b>Abstract:</b> Scaffolding is useful for making quick text edits and minor structural 
				changes to existing xml files.
			</p>
			<p>
				<b>Warning:</b> This script can make modifications to the contents of your MarkLogic 
				database.  <b>USE AT YOUR OWN RISK</b>.  Do not make this file accessible in a production
				environment unless you really know what you're doing.  <b>There are still unresolved bugs</b>, 
				see below.
			</p>
			<p><b>Notes:</b></p>
				<ul>
					<li>Able to make text-node updates to any xml documents it has access to.</li>
					<li>Able to duplicate (insert) sibling elements, and remove elements altogether.  Careful
						when removing, if you remove the last node of it's kind, there's no way to bring it back.</li>
					<li><b>Doesn't handle elements which contain both text-node AND element-node children</b>.
						For example, an element containing markup-like content such as 
						{ xdmp:quote(<message>xquery is <b>lots</b> of <i>fun</i></message>) } will be read as
						{ xdmp:quote(<message>xquery is lots of fun</message>) }.</li>
					<li>The MarkLogic user executing this script must have permission to execute xdmp:eval.</li>
					<li>This file is entirely self-contained, no dependancies.  Just drop it anywhere in your
						project and go.</li>
					<li>Apologies for the complete lack of commenting, this is still in the works.</li>
				</ul>
			<p>
				<b>Bugs:</b> When saving a document containing attributes which are part of an element which
					has only text-node children (ex. { xdmp:quote(<sign width="10" height="5">hello</sign>) }), 
					those attributes vanish (ex. { xdmp:quote(<sign>hello</sign>) }).
					Attributes which are part of an element which has only element-node children 
					are saved successfully.  If you grab the command from the log and execute it standalone (in 
					CQ, for example), given the same document, the attributes are saved successfully.
					I still have no idea why this is happening, see line 41 and 43 of this file.
			</p>
			<p>
				<b>Motivation:</b> Our website translations reside in xml files.  I find it useful to view a 
				translation with Scaffolding to make quick edits and additions to the output phrases, rather than
				editing  a local file and re-loading it into MarkLogic for every change.
			</p>
			<p>
				<b>Contact:</b> Please direct all comments/suggestions to <b>eric.palmitesta@utoronto.ca</b>,
				all feedback is welcome.  I'd also love to know what you're using this utility for, and if you 
				found it useful.
			</p>
			<p>Eric Palmitesta<br />eric.palmitesta@utoronto.ca</p>
		</div>
	)
}

define function display-dir($uri as xs:string)
{
	display-page($uri,
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

define function display-file($uri as xs:string)
{
	display-page($uri,
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

(:
	The meat and potatoes of Scaffolding.  Recurively walks the xml tree,
	displaying its elements and attributes in html with appropriate text boxes.
:)
define function display-element-contents($elements as element()*)
{
	for $element in $elements
	return
		<ul>
			<li>{
				open-tag($element),
				if (exists($element/text()) or not(exists($element/element()))) then
					let $text := string($element)
					return
						if (string-length($text) gt 30) then
							<textarea name="__element__{ xdmp:path($element) }" rows="3" cols="30">{ $text }</textarea>
						else
							<input type="text" name="__element__{ xdmp:path($element) }" value="{ $text }"
							size="{ min((30, string-length($text))) }" />
				else
					display-element-contents($element/element()),
				close-tag($element)
			}&nbsp;{
				if (not($element = root($element))) then add-remove-links($element)
				else ()
			}</li>
		</ul>
}

define function add-remove-links($element as element())
{
	<span class="sub">
		(<a href="?uri={ base-uri($element) }&insert={ xdmp:path($element) }" title="insert">+</a>
		/
		<a href="?uri={ base-uri($element) }&remove={ xdmp:path($element) }" title="remove">-</a>)
	</span>
}

define function open-tag($element as element())
as xs:string
{
	if (not($element/@*)) then
		concat('&lt;', node-name($element), '&gt; ')
	else (
		concat('&lt;', node-name($element)),
		for $attribute in $element/@*
		let $text := string($attribute)
		return (
			concat(' ', node-name($attribute), '='),
			<input type="text" name="__attribute__{ xdmp:path($attribute) }" value="{ $text }" 
			size="{ min((30, string-length($text)+5)) }" />
		),
		'&gt; '
	)
}

define function close-tag($element as element())
as xs:string
{
	concat(' &lt;/', node-name($element), '&gt;')
}

(:
	Takes a string such as "/path/to/file.xml", and returns a
	slash-delimited list of links to each token in the path:
	/<a href="/path">path</a>/<a href="/path/to">to</a>/<a href="/path/to/file.xml">file.xml</a>
:)
define function display-path($path as xs:string)
as element(span)
{
	<span>{
		let $link := ''
		for $token in tokenize($path, '/')[2 to last()]
		return
			(xdmp:set($link, concat($link, '/', $token)),
			<span>/<a href="?uri={ $link }">{ $token }</a></span>)
	}</span>
}

define function insert-duplicate-sibling($uri as xs:string, $insert-path as xs:string)
{
	let $node := concat("(doc('", $uri, "')", $insert-path, ')[last()]')
	return
		xdmp:eval(concat("xdmp:node-insert-after(", $node, ", ", $node, ")"))
}

define function remove-element($uri as xs:string, $remove-path as xs:string)
{
	let $node := concat("(doc('", $uri, "')", $remove-path, ')[last()]')
	return
		xdmp:eval(concat("xdmp:node-delete(", $node, ")"))
}

define function save-fields($uri as xs:string, $fields as xs:string*)
{
	for $path in $fields
	return
		if (starts-with($path, '__element__')) then
			update-element($uri, substring-after($path, '__element__'), xdmp:get-request-field($path))
		else if (starts-with($path, '__attribute__')) then
			update-attribute($uri, substring-after($path, '__attribute__'), xdmp:get-request-field($path))
		else ()
}

(:
	Called by save-fields, constructs a new element containing $value, to replace
	the element residing at $path in $uri.
:)
define function update-element($uri as xs:string, $path as xs:string, $value as xs:string)
{
	let $old-node := concat("doc('", $uri, "')", $path)
	let $new-node := concat("element { '", tokenize(string-join(tokenize($path, "\[\d+\]"), ''), '/')[last()], "' } { '", replace($value, "'", "''"), "' }")
	let $z := xdmp:log(concat("xdmp:node-replace(", $old-node, ", ", $new-node, ")"))
	return
		xdmp:eval(concat("xdmp:node-replace(", $old-node, ", ", $new-node, ")"))
}

(:
	Called by save-fields, constructs a new attribute containing $value, to replace
	the attribute residing at $path in $uri.
:)
define function update-attribute($uri as xs:string, $path as xs:string, $value as xs:string)
{
	let $old-node := concat("doc('", $uri, "')", $path)
	let $new-node := concat("attribute { '", substring-after($path, '@'), "' } { '", replace($value, "'", "''"), "' }")
	let $z := xdmp:log(concat("xdmp:node-replace(", $old-node, ", ", $new-node, ")"))
	return
		xdmp:eval(concat("xdmp:node-replace(", $old-node, ", ", $new-node, ")"))
}

(: THE REAL WORK STARTS HERE :)

let $save := xdmp:get-request-field('save', '')
let $insert := xdmp:get-request-field('insert', '')
let $remove := xdmp:get-request-field('remove', '')
let $uri := xdmp:get-request-field('uri', '')
return
	if ($save) then
		(save-fields($uri, xdmp:get-request-field-names()),
		xdmp:redirect-response(concat('?uri=', $uri)))
	else if ($insert) then
		(insert-duplicate-sibling($uri, $insert),
		xdmp:redirect-response(concat('?uri=', $uri)))
	else if ($remove) then
		(remove-element($uri, $remove),
		xdmp:redirect-response(concat('?uri=', $uri)))
	else if (ends-with($uri, '.xml')) then
		display-file($uri)
	else if ($uri) then
		display-dir($uri)
	else
		display-info()