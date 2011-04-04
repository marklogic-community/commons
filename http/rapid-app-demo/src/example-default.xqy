import module namespace page="http://www.marklogic.com/ps/versi/page-layout" at "modules/page-layout.xqy"
import module namespace dis="http://www.marklogic.com/ps/versi/display" at "modules/display.xqy"
import module namespace widg="http://www.marklogic.com/ps/versi/widgets" at "modules/widgets.xqy"

declare namespace htm="http://www.w3.org/1999/xhtml"

let $params := (: Recommended that lib-uitools is used to generate params from request :)
    <params>
        <sidearea>true</sidearea>
    </params>
let $page-info :=
    page:build-page-info(
    	"Versi Template", (: title :)
    	(), (: head elements :)
    	() (: body.onload javascript :)
	)
let $content :=
    (
    page:two-column(
        "secondary", (: Layout Type: "secondary", "sidebar" :)
        (: Primary Column Contents - this markup should be put in the display file for reuse and modularization :)
		<div>
    		<div class="text-content">
    			<h2>Welcome to Versi!</h2>
    			<p>This is a sample page from the Versi template. You will note that the template is built to be highly customizable. Using the example pages
    			in this directory, you should be able to quickly build a user interface that is rich, easy to use, XHTML compliant, and save you oodles of time.</p>
    			<p>To see more examples of Versi in action, take a look at these sample documents:</p>
    			<ul>
    				<li><a href="template.xqy">Generic Template</a></li>
    				<li><a href="example-columns.xqy">Example Column Layouts</a></li>
    				<li><a href="example-width.xqy">Custom Width and Header</a></li>
    			</ul>
    		</div>
    		{widg:pagination()}
		</div>,
        (: Second Column Contents :)
        widg:stack-menu()
    )
    )

return page:output($params, $page-info, $content)