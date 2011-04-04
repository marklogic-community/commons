(:
 :
 : This module is meant to be a reference. Copy widgets into the
 : display module to customize. 
 :
 :)

module "http://www.marklogic.com/ps/versi/widgets"

declare namespace htm="http://www.w3.org/1999/xhtml"

(:
 : Function List
 : block-menu
 : drop-nav
 : formatted-form
 : main-menu-simple
 : main-menu-split
 : main-menu-quicksearch
 : messages
 : pagination
 : quicksearch
 : stack-menu
 :)

(:
    The block menu is a 2-level drop down menu that is intended for use in the sidebar.
:)
define function block-menu ()
{
	<div class="blockMenuContainer">
    	<h3>Topics</h3>
    	<ul class="blockMenu">
    		<li><div>
    			<a href="javascript:void(0);">All Topics</a>
    		</div></li>
    		<li>
    			<div class="current">
    				<a href="javascript:void(0);">Group A</a>
    	 			<a class="toggle" href="#" onclick="$('tdwc1').toggle();swapPlusMinus(this);return false;">
    				&ndash;
    	 			</a>
     			</div>
    			<ul id="tdwc1">
    				<li><a href="javascript:void(0);" >
    					Item 1
    				</a></li>	 			
    				<li><a href="javascript:void(0);" class="current">
    					Item 2
    				</a></li>	 			
    				<li><a href="javascript:void(0);" >
    					Item 3
    				</a></li>	 			
    			</ul>
    		</li>
    		<li>
    			<div>
    				<a href="javascript:void(0);">Group B</a>
    	 			<a class="toggle" href="#" onclick="$('tdwc2').toggle();swapPlusMinus(this);return false;">
    				+
    	 			</a>
     			</div>
    			<ul id="tdwc2">
    				<li><a href="javascript:void(0);" >
    					Item 4
    				</a></li>	 			
    				<li><a href="javascript:void(0);" >
    					Item 5
    				</a></li>	 			
    				<li><a href="javascript:void(0);" >
    					Item 6
    				</a></li>	 			
    			</ul>
     			<script type="text/javascript">$('tdwc2').toggle();</script>
    		</li>
    	</ul>
    </div>
}

(:
    This is meant to be used inside the <div id="header"> of the template,
    after the logo/site title, and provides information on every page to the
    user. Can be used to display login information or useful links to the user.
    Alternatively, you can use the Utility Area built into the template. -->
:)
define function drop-nav ()
{
	<div class="dropnav">
	    Logged in as: <strong>Superman</strong>{" "}
    	<ul class="flatlinks">
    		<li><a href="/logout.html">Logout</a></li>
    	</ul>
	</div>
}

(:
    The formatted form allows for attractive, user-friendly forms to be
    built quickly, with very little code.
:)
define function formatted-form ()
{
	<form class="formatted" method="POST" action="form.html">
		<p><label class="nofield">Username:</label> <strong>Username</strong></p>
		<p><label for="firstName">First Name:</label>  <input type="text" name="first" value=""/></p>
		<p><label for="lastName">Last Name:</label> <input type="text" name="last" value=""/></p>
		<p><label for="email">Email:</label> <input type="text" name="email" value="" /></p>
		<p><label for="zipcode">Zip:</label> <input type="text" name="zip" style="width:100px;" value="" /></p>
		<p><textarea rows="6">{" "}</textarea></p>
		<p><input type="submit" name="submit" value="Submit" class="button" /></p>
	</form>
}

(:
    Versi's main menu allows for highly flexible layouts. Menu tabs can be positioned to
    the right and left, and a sidebar area for standard links and other
    widgets can be included as well. Here are three sample main menus.
:)

(:
    Example of a standard tab menu.
:)
define function main-menu-simple ()
{
	<ul class="menu">
		<li class="current_page_item"><a href="default.html">Home</a></li>{" "}
		<li><a href="post.html">Post</a></li>{" "}
		<li><a href="explore.html">Explore</a></li>
	</ul>
}

(:
    Example of a menu with a tab positioned to the right.
:)
define function main-menu-split ()
{
	<ul class="menu">
		<li class="current_page_item"><a href="default.html">Home</a></li>{" "}
		<li><a href="post.html">Post</a></li>{" "}
		<li><a href="explore.html">Explore</a></li>
		<li class="admintab"><a href="myaccount.html">My Stuff</a></li>
	</ul>
}

(:
    Example of a menu with a quicksearch bar and links positioned to the right.
:)
define function main-menu-quicksearch ()
{
	<ul class="menu">
		<li class="current_page_item"><a href="default.html">Home</a></li>{" "}
		<li><a href="post.html">Post</a></li>{" "}
		<li><a href="explore.html">Explore</a></li>
	</ul>
	,
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
}

(:
    Messages allow for user feedback to be displayed prominantly on the
    page. Please use them above the page header.
:)
define function messages ()
{
	<div class="message success"><p>This is a successful message!</p></div>
	,
	<div class="message error"><p>This is an error message!</p></div>
	,
	<div class="message warning"><p>This is an warning message!</p></div>
}

(:
    Pagination can be placed anywhere on the page.
:)
define function pagination ()
{
    <div class="pages">
    	<a href="javascript:void(0);" class="nextprev" title="Go to Previous">&laquo; Previous 5</a>
    	<a href="javascript:void(0);" title="">6</a> 
    	<span class="current">7</span>
    	<a href="javascript:void(0);" title="">8</a> 
    	<a href="javascript:void(0);" title="">9</a> 
    	<a href="javascript:void(0);" title="">10</a> 
    	<a href="javascript:void(0);" class="nextprev" title="Go to Next Page">Next 5 &raquo;</a>
    </div>
}

(:
    The quicksearch is meant to be placed in one of two
    places. It can be placed next to the menu items in the
    header, or in the far right corner of the page in the
    utility area.
:)
define function quicksearch ()
{
	<div class="quicksearch">
		<form method="post" action="/search_html.html">
			<input type="hidden" name="adv_search_flg" value="n" class="hide" />{" "}
			<input type="text" name="search_text" id="quicksearch_q" class="textbox" value="" />{" "}
			<input type="submit" value="Search" class="button" />
		</form>
	</div>
}

(:
    The stackmenu is the standard form of menu widget for the sidebar
    or secondary sidebar. It allows for headers and highlighted menu items.
:)
define function stack-menu ()
{
    <div class="stackMenuContainer">
        <h3 class="stackMenu">Related Links</h3>
    	<ul class="stackMenu">
    		<li><a href="javascript:void(0);">Semantic Web</a></li>
    		<li><a href="javascript:void(0);">Metadata and You</a></li>
    	</ul>
    	<h3 class="stackMenu">Download</h3>
    	<ul class="stackMenu">
    		<li><a
    			href="javascript:void(0);"
    			title="">What's new?</a></li>
    		<li><a
    			href="javascript:void(0);"
    			title="">Instructions</a></li>
    		<li><a
    			href="javascript:void(0);"
    			title="">White Paper</a></li>
    	</ul>
    </div>
}