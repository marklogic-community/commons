(:
 :
 : This module is for user-defined display functions, such as custom widgets.
 : Example main modules are already wired up to this library. 
 :
 :)

module "http://www.marklogic.com/ps/versi/display"

declare namespace htm="http://www.w3.org/1999/xhtml"

define function main-content($params as element(params))
{
    text {"Main Content"}
}

define function example-a($params as element(params))
{
    <div>
    	<h3>Menu Category a</h3>
    	<ul>
    		<li>Item 1</li>
    		<li>Item 2</li>
    	</ul>
    	<h3>Menu Category b</h3>
    	<ul>
    		<li>Item a</li>
    		<li>Item b</li>
    	</ul>
	</div>
}

define function example-b($params as element(params))
{
    <div>
        <h3>Menu Category 1</h3>
		<ul>
			<li>Item 1</li>
			<li>Item 2</li>
		</ul>
		<h3>Menu Category 2</h3>
		<ul>
			<li style="whitespace:nowrap">Item a bakakwekfwjelfwe wflwaefw awf;lwekfjwe a wfe</li>
			<li>Item b</li>
		</ul>
		<h3>Menu Category 1</h3>
		<ul>
			<li>Item 1</li>
			<li>Item 2</li>
		</ul>
		<h3>Menu Category 2</h3>
		<ul>
			<li style="whitespace:nowrap">Item a bakakwekfwjelfwe wflwaefw awf;lwekfjwe a wfe</li>
			<li>Item b</li>
		</ul>
		<h3>Menu Category 1</h3>
		<ul>
			<li>Item 1</li>
			<li>Item 2</li>
		</ul>
		<h3>Menu Category 2</h3>
		<ul>
			<li style="whitespace:nowrap">Item a bakakwekfwjelfwe wflwaefw awf;lwekfjwe a wfe</li>
			<li>Item b</li>
		</ul>
		<h3>Menu Category 1</h3>
		<ul>
			<li>Item 1</li>
			<li>Item 2</li>
		</ul>
		<h3>Menu Category 2</h3>
		<ul>
			<li style="whitespace:nowrap">Item a bakakwekfwjelfwe wflwaefw awf;lwekfjwe a wfe</li>
			<li>Item b</li>
		</ul>
	</div>
}
