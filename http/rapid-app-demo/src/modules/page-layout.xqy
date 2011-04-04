(:~
 : Page Layout library.
 : This module implements core Versi page layout functions. Modify this
 : module to customize the Versi layout for your application.
 :)
module "http://www.marklogic.com/ps/versi/page-layout"

import module namespace dis="http://www.marklogic.com/ps/versi/display" at "display.xqy"
import module namespace widg="http://www.marklogic.com/ps/versi/widgets" at "widgets.xqy"

declare namespace htm="http://www.w3.org/1999/xhtml"
declare namespace x=""

(:~
 : Creates a page-info element which is used to pass necessary information to the
 : page template. This method should be overloaded to pass additional information
 : to the template. 
 :
 : @param $html-title The title that will display in the browser title bar.
 : @param $head-elements Additional elements like link and script that can go in the page head.
 : @param $onloadEvent A JavaScript snippet that will run on page load.
 : @return A page-info element containing information for the template.
 :)
define function build-page-info(
	$html-title as xs:string,
	$head-elements as element()*,
	$onloadEvent as xs:string?
	) as element(page-info)
{
<page-info>
	<html-title>{$html-title}</html-title>
	<head-elements>{$head-elements}</head-elements>
	<onload-events>{$onloadEvent}</onload-events>
</page-info>
}

(:~
 : Generates a valid XHTML document with DOCTYPE.
 :
 : @param $params The page parameters, typically generated from the page request.
 : @param $page-info An element that contains rendering information to the template.
 : @param $content The content of the page.
 : @return A valid XHTML document with DOCTYPE.
 :)
define function output(
	$params as element(params),
	$page-info as element(page-info),
	$content as item()*
	)
{
    let $doctype := '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
    let $html := template($params, $page-info, $content)
    return (xdmp:set-response-content-type("text/html; charset=utf-8"), $doctype, $html)
}

(:~
 : Generates a one-column layout.
 :
 : @param $primary The contents of the primary column.
 : @return A content-filled one-column layout.
 :)
define function one-column($primary as item()*) as element()
{
	<div id="one_col">
		<div id="primary">
		{$primary}
		</div>
	</div>
}

(:~
 : Generates a default two-column layout.
 : 
 : @param $primary The contents of the primary column.
 : @param $second The contents of the second column.
 : @return A content-filled two-column layout.
 :)
define function two-column($primary as node()*, $second as item()*) as element()
{
    two-column((), $primary, $second)
}

(:~
 : Generates a two-column layout.
 : 
 : @param $layout The type of second column to use for the page. Values are
 : "secondary" or "sidebar". If empty, the default of "sidebar" will be used. 
 : @param $primary The contents of the primary column.
 : @param $second The contents of the second column.
 : @return A content-filled two-column layout.
 :)
define function two-column($layout as xs:string?, $primary as item()*, $second as item()*) as element()
{
    let $layout := if ($layout) then fn:lower-case($layout) else "sidebar"
    return
    if ($layout = "secondary") then
        <div id="two_col">
        	<div id="primary">
        	{$primary}
        	</div>
        	<hr />
        	<div class="secondary">
        	{$second}
        	</div>
        </div>
   else if ($layout = "sidebar") then
        <div id="two_col">
        	<div id="sidebar">
        	{$second}
        	</div>
            <hr />
        	<div id="primary">
        	{$primary}
        	</div>
        </div>
   else ()
}

(:~
 : Generates a three-column layout.
 : 
 : @param $primary The contents of the primary column.
 : @param $sidebar The contents of the sidebar column.
 : @param $secondary The contents of the secondary column.
 : @return A content-filled three-column layout.
 :)
define function three-column($primary as item()*, $sidebar as item()*, $secondary as item()*) as element()
{
	<div id="three_col">
		<div id="sidebar">
        {$sidebar}
		</div>
		<hr />
		<div id="primary">
        {$primary}
		</div>
		<hr />
		<div class="secondary">
        {$secondary}
		</div>
	</div>
}

(:~
 : Generates a three-column layout.
 : 
 : @param $primary The contents of the primary column.
 : @param $sidebar The contents of the sidebar column.
 : @param $secondary The contents of the secondary column.
 : @return A content-filled three-column layout.
 :)
define function utility-area($params as element(params), $page-info as element(page-info))
{
    (: This line should be replaced with true/false based on design requirements :)
    let $utility := fn:empty($params/utility) or xs:boolean($params/utility)
    return
    if ($utility) then
        <div id="utility">
    		<ul class="flatlinks">
    		<li class="first">This is the utility area.</li>{" "}
    		<li><a href="http://www.eff.org/">EFF</a></li>{" "}
    		<li><a href="http://www.google.com/">Google</a></li>{" "}
    		<li><a href="http://en.wikipedia.org/">Wikipedia</a></li>{" "}
    		</ul>
    		<div class="quicksearch">
    			<form method="get" action="explore.html">{" "}
    				<input type="text" name="q" id="quicksearch_q" class="textbox" />{" "}
    				<input type="submit" value="Search" class="button" /></form>
    		</div>
    	</div>
    else ()
}

(:~
 : Displays the drop navigation which contains user info, such as a cart,
 : login/logout, etc.
 :
 : @param $params The page parameters.
 : @param $page-info An element that contains rendering information for
 : the template, and template elements.
 : @return The drop-nav element.
 :)
define function drop-nav($params as element(params), $page-info as element(page-info))
{
    (: This line should be replaced with true/false based on design requirements :)
    let $drop-nav := fn:exists($params/dropnav) and xs:boolean($params/dropnav)
    return
    if ($drop-nav) then
    	<div class="dropnav">
    	    Logged in as: <strong>Superman</strong>{" "}
        	<ul class="flatlinks">
        		<li><a href="/logout.html">Logout</a></li>
        	</ul>
    	</div>
    else ()
}

(:~
 : Displays the menu bar and includes an admin tab or quicksearch box.
 :
 : @param $params The page parameters.
 : @param $page-info An element that contains rendering information for
 : the template, and template elements.
 : @return The menu element.
 :)
define function menu($params as element(params), $page-info as element(page-info))
{
    (: This line should be replaced with true/false based on design requirements :)
    let $sidearea := fn:exists($params/sidearea) and xs:boolean($params/sidearea)
    return
    (
    <ul class="menu">
		<li class="current_page_item"><a href="default.html">Home</a></li>{" "}
		<li><a href="post.html">Post</a></li>{" "}
		<li><a href="explore.html">Explore</a></li>

        {
        if (fn:not($sidearea)) then
		    <li class="admintab"><a href="myaccount.html">My Stuff</a></li>
		else ()
		}

	</ul>,
    if ($sidearea) then
    	<div class="sidearea">
    		<ul class="flatlinks">
    			<li><a href="/search_html.xqy?adv_search_flg=y">Advanced</a></li>
    		</ul>
    		<div class="quicksearch">
    			<form method="post" action="/search_html.xqy">
    				<input type="hidden" name="adv_search_flg" value="n" class="hide" />{" "}
    				<input type="text" name="search_text" id="quicksearch_q" class="textbox" value="" />{" "}
    				<input type="submit" value="Search" class="button" />
    			</form>
    		</div>
    	</div>
    else ()
    )
}

(:~
 : Displays the subheader which is displayed below the header and menubar.
 :
 : @param $params The page parameters.
 : @param $page-info An element that contains rendering information for
 : the template, and template elements.
 : @return The subheader element.
 :)
define function subheader($params as element(params), $page-info as element(page-info))
{
    (: This line should be replaced with true/false based on design requirements :)
	let $subheader := fn:empty($params/subheader) or xs:boolean($params/subheader)
	return
	if ($subheader) then
    	<div id="subheader">
    		<p>This is the subheader area.</p>
    	</div>
    else ()
}

(:~
 : Displays the footer at the bottom of the page.
 :
 : @param $params The page parameters.
 : @param $page-info An element that contains rendering information for
 : the template, and template elements.
 : @return The footer element.
 :)
define function footer($params as element(params), $page-info as element(page-info))
{
    <div id="footer"><small>Powered by <a href="http://w3.org/">XHTML</a>.</small></div>
}

(:~
 : Displays the page template.
 :
 : @param $params The page parameters.
 : @param $page-info An element that contains rendering information for
 : the template, and template elements.
 : @param $content The page contents.
 : @return The page template including the content of the page.
 :)
define function template(
	$params as element(params),
	$page-info as element(page-info),
	$content as item()*
	) as element(htm:html)
{
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<title>{fn:string($page-info/x:html-title)}</title>
	<link rel="stylesheet" type="text/css" media="screen" href="css/style.css" />
	<script language="javascript" src="js/prototype.js" type="text/javascript">{" "}</script>
	<script language="javascript" src="js/ui.js" type="text/javascript">{" "}</script>
	<script language="javascript" src="js/appspecific.js" type="text/javascript">{" "}</script>
	{$page-info/x:head-elements/*}
</head>
<body>
{ if (fn:string($page-info/x:onload-events) ne "") then attribute onload {fn:string($page-info/x:onload-events)} else () }
<div id="page">
	{utility-area($params, $page-info)}
	<hr />
	<div id="header">
		{drop-nav($params, $page-info)}
		<h1>Versi Template</h1>
		<p class="description">The template for the man you are.</p>
		{menu($params, $page-info)}
	</div>
	{subheader($params, $page-info)}
	<hr />
	<div id="content">
		{$content}
	</div>
	<div class="clear"></div>
</div>
<hr />
{footer($params, $page-info)}
</body>
</html>
}