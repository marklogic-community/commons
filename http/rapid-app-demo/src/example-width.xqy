import module namespace page="http://www.marklogic.com/ps/versi/page-layout" at "modules/page-layout.xqy"
import module namespace dis="http://www.marklogic.com/ps/versi/display" at "modules/display.xqy"
import module namespace widg="http://www.marklogic.com/ps/versi/widgets" at "modules/widgets.xqy"

declare namespace htm="http://www.w3.org/1999/xhtml"

let $params := (: Recommended that lib-uitools is used to generate params from request :)
    <params>
        <dropnav>true</dropnav>
        <utility>false</utility>
        <sidearea>true</sidearea>
        <subheader>false</subheader>
    </params>
let $page-info :=
    page:build-page-info(
    	"Versi Template", (: title :)
    	(<link rel="stylesheet" type="text/css" media="screen" href="appspecific-width.css" />), (: head elements :)
    	() (: body.onload javascript :)
	)
let $content :=
    (
    page:two-column(
        "sidebar", (: Layout Type: "secondary", "sidebar" :)
        (: Primary Column Contents :)
        <div>
            {widg:messages()}
        	<h2>Customized Width and Header</h2>
			<p>If you like this layout, view the <a href="width.css">width.css</a> file.</p>
			{widg:formatted-form()}
		</div>, 
        widg:block-menu() (: Second Column Contents :)
    )
    )

return page:output($params, $page-info, $content)