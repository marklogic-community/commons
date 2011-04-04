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
    page:one-column(
        (attribute style {"background:lightgrey;"}, dis:main-content($params)) (: Primary Column Contents :)
    ),
    page:two-column(
        "sidebar", (: Layout Type: "secondary", "sidebar" :)
        (attribute style {"background:lightgrey;"}, dis:main-content($params)), (: Primary Column Contents :)
        (attribute style {"background:lightblue;"}, dis:example-a($params)) (: Second Column Contents :)
    ),
    page:two-column(
        "secondary", (: Layout Type: "secondary", "sidebar" :)
        (attribute style {"background:lightgrey;"}, dis:main-content($params)), (: Primary Column Contents :)
        (attribute style {"background:lightblue;"}, dis:example-a($params)) (: Second Column Contents :)
    ),
    page:three-column(
        (attribute style {"background:lightgreen;"}, dis:main-content($params)), (: Primary Column Contents :)
        (attribute style {"background:lightgrey;"}, dis:example-b($params)), (: Sidebar Column Contents :)
        (attribute style {"background:lightblue;"}, dis:example-a($params)) (: Secondary Column Contents :)
    )
    )

return page:output($params, $page-info, $content)