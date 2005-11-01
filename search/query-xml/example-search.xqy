import module namespace stox  = "http://marklogic.com/query-xml" at "query-xml.xqy"

(:
	The following function call will produce a XML document like:
	<search>
		<term>http://bob.com</term>
		<term field="allintitle">xquery rocks</term>
		<term op="-" field="allintitle">java</term>
		<term field="site">xquery.com</term>
		<term op="-">xslt</term>
		<term op="-">not this phrase</term>
	</search>
:)

stox:searchToXml('http://bob.com allintitle:"xquery rocks" -allintitle:java site:xquery.com -xslt -"not this phrase"',
		("link", "site", "filetype", "allintitle", "allintext", "allinurl", "allinanchor"),
		("+", "-")
	)
