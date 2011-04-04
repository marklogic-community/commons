import module namespace page="http://www.marklogic.com/ps/versi/page-layout" at "modules/page-layout-demo.xqy"
import module namespace dis="http://www.marklogic.com/ps/versi/display" at "modules/display-demo.xqy"
import module namespace uit="http://www.marklogic.com/ps/lib/lib-uitools" at "modules/lib-uitools.xqy"

declare namespace htm="http://www.w3.org/1999/xhtml"

let $params := (: Recommended that lib-uitools is used to generate params from request :)
    uit:load-params()
let $page-info :=
    page:build-page-info(
    	fn:concat("Search Help - ",$dis:SITE-TITLE), (: title :)
    	<link rel="stylesheet" type="text/css" media="screen" href="css/appspecific-demo.css" />, (: head elements :)
    	() (: body.onload javascript :)
	)
let $content :=
    (
    page:one-column(
		<div>
    		<h2>Search Syntax</h2>
<div style="font-size:110%">
<p>This site allows the user to enter Google-like free-text
strings that represent complex queries.</p>
<p><span style="mso-bookmark:_Toc154312728"><b
>Stemmed searches</b>: The terms the user
enters will match any term that shares the word root. For example, &ldquo;goose&rdquo; will
match both &ldquo;goose&rdquo; and &ldquo;geese&rdquo;, and &ldquo;run&rdquo; will match &ldquo;run,&rdquo; &ldquo;runs,&rdquo; &ldquo;ran,&rdquo; and
&ldquo;running&rdquo;. Please note that stemming does not cross parts of speech.</span></p>
<p><span style="mso-bookmark:_Toc154312728"><b
>Phrase search</b>: Terms that are wrapped
by double quotes will be searched as a phrase, meaning all words must appear
next to each other. Stemming will be enabled for phrase searches, meaning
&ldquo;intellectual property&rdquo; will match &ldquo;intellectual property&rdquo; and &ldquo;intellectual
properties.&rdquo;</span></p>
<p><span style="mso-bookmark:_Toc154312728"><b
>Flexible syntax</b>: Searches are not case
sensitive or diacritic sensitive (e.g. accents on characters). They are,
however, punctuation sensitive.</span></p>
<p><b>Fielded search</b>: The
user can also specify fields in their search term string. For example:</p>
<ul style="margin-left:15px;" type="disc">
 <li style="mso-list:l0 level1 lfo1;tab-stops:list .5in left 2.5in"><b>Title</b>: using
     &ldquo;title:"gas"&rdquo;</li>
</ul>
<p style="tab-stops:2.5in">To search within a field using a
word query, use the color character (&ldquo;:&rdquo;). To search for an exact value use the
equality character (&ldquo;=&rdquo;). For example, &ldquo;pub=ABCD&rdquo; will search for documents
whose publication abbreviation equals &ldquo;ABCD&rdquo;. The query &lsquo;author:&rdquo;Joe Smith&rdquo;&rsquo;
will search for bylines that contain the author &ldquo;Joe Smith&rdquo;. It is recommended
that colon characters be used for most searches.</p>
<p><b>AND-joined terms</b>:
By default all terms and phrases will be required to appear in any matching
document.</p>
<p><b>OR Operators</b>: OR
operators provide the ability to search using a query like &ldquo;judge OR jury&rdquo; to
return documents that contains either of those terms. Alternatively, a single
pipe character can be used in place of an OR operator (e.g. &ldquo;judge | jury&rdquo;). OR
operators without parentheses include the two terms or phrases next to the
operator. For example, &ldquo;judge OR jury intellectual property&rdquo; is the same as
&ldquo;(judge OR jury) intellectual property&rdquo;.</p>
<p><b>NOT Operators</b>:
NOT operators provide the ability to exclude terms, groups or phrases from the
search results. A search for &lsquo;NOT intellectual&rsquo; will return documents that do
not contain &ldquo;intellectual&rdquo; in them. Alternatively, a dash character can be used
in place of a NOT operator (e.g. &ldquo;-intellectual&rdquo;) The NOT operator acts only on
its following term, group or phrase. </p>
<p><b>Grouped terms &amp;
phrases</b>: When using Boolean operators the user can choose to group terms
together by using parentheses. For example &ldquo;judge OR (hung jury)&rdquo; will find
documents that contain either &ldquo;judge&rdquo; or &ldquo;hung&rdquo; and &ldquo;jury&rdquo;.</p>
<p><b>Near queries</b>: Near
queries offer the ability to perform proximity searches. For example, &ldquo;dog NEAR
bite&rdquo; would return documents that contained &ldquo;dogs have bit humans&rdquo;, &ldquo;dogs do
bite people&rdquo;, or &ldquo;the cat was bitten by the dog&rdquo;. To specify the number of
words away two words or phrases should be, use the syntax NEAR/<i
style='mso-bidi-font-style:normal'>n</i> where <i style='mso-bidi-font-style:
normal'>n</i> is the distance in words, such as &ldquo;dog NEAR/5 bite&rdquo; where
documents will match when &ldquo;bite&rdquo; is within 5 words of &ldquo;dog&rdquo;. Near queries work
with phrases, but do not work with groups.</p>
</div>
		</div>
    )
    )

return page:output($params, $page-info, $content)