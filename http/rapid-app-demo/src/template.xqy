import module namespace page="http://www.marklogic.com/ps/versi/page-layout" at "modules/page-layout.xqy"
import module namespace dis="http://www.marklogic.com/ps/versi/display" at "modules/display.xqy"

declare namespace htm="http://www.w3.org/1999/xhtml"

let $params := (: Recommended that lib-uitools is used to generate params from request :)
    <params />
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
        "Main Content", (: Primary Column Contents :)
        "This is the secondary sidebar area" (: Second Column Contents :)
        )
    )

return page:output($params, $page-info, $content)