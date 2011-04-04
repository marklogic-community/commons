import module namespace dis="http://www.marklogic.com/ps/versi/display" at "modules/display-demo.xqy"
import module namespace sdis="http://www.marklogic.com/ps/versi/search-ui" at "modules/search-ui.xqy"
import module namespace uit="http://www.marklogic.com/ps/lib/lib-uitools" at "modules/lib-uitools.xqy"

let $params := uit:load-params()
return
	(
	if($params/action = "show-section") then sdis:show-section($params)
	else
		()
	)                                                                                                                                                                                                                                                                                                                                                                                                                                                                             