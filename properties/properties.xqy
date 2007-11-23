(:~
 :
 : Copyright 2007 Ryan Grimm
 :
 : Many times, an application needs to store some persistant configuration
 : properties.  Currently, the only way to really do this using MarkLogic is to
 : create a document in the database that has this information.  While this
 : practice works fine, the overhead of fetching the document from the database on
 : a frequent basis seems unnecessary.
 : 
 : This module is essentially a hack to get around this limitation and provide
 : similar functionality that Java gives with property sheets.  MarkLogic has the
 : ability to configure predefined namespaces in the server itself.  We can use
 : these namespaces as key value pairs.  The namespaces are defined in the server
 : Admin (Admin -> Groups -> (group name) -> Namespaces).
 : 
 : 
 : Usage:
 : First you'll need to define a new namespace in the server.  The namespace
 : prefix should be the key in your key/value pair.  The namespace URI should be
 : in the form of: http://xqdev.com/prop/<type>/<value>.  The <type> in the URI
 : can be one of the approved XML Schema types (eg: xs:string, xs:date, xs:boolean).
 : The <value> part of the URI will end up being the value in your key/value pair.
 : 
 : The approved XML Schema types are:
 : xs:string, xs:boolean, xs:decimal, xs:float, xs:double, xs:duration,
 : xs:dateTime, xs:time, xs:date, xs:gYearMonth, xs:gYear, xs:gMonthDay, xs:gDay
 : xs:gMonth, xs:hexBinary, xs:base64Binary, xs:QName, xs:integer,
 : xs:nonPositiveInteger, xs:negativeInteger, xs:long, xs:int, xs:short, xs:byte,
 : xs:nonNegativeInteger, xs:unsignedLong, xs:unsignedInt, xs:unsignedShort,
 : xs:unsignedByte, xs:positiveInteger
 : 
 : If you have specified a type that doesn't match the above list, it will be
 : returned as an xs:string.
 : 
 : Example URI's:
 : http://xqdev.com/prop/boolean/true returns true()
 : http://xqdev.com/prop/string/foo%20bar returns "foo bar"
 : http://xqdev.com/prop/string/foo/bar returns "foo/bar"
 : http://xqdev.com/prop/date/2007-11-22 returns xs:date("2007-11-22")
 : 
 : 
 : Use Case:
 : Lets say your application needs to know if it is being executed in a production
 : or development environment.  It's going to use this information to correctly
 : write out links in your application.
 : 
 : To do this, lets configure a namespace in the server with a prefix of
 : 'deployment_mode' and a URI of 'http://xqdev.com/prop/string/production'.
 : 
 : Once that is done, calling prop:get("deployment_mode") will return "production"
 : typed as a xs:string.
 :
 :
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 :     http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :
 : @author Ryan Grimm (grimm@xqdev.com)
 : @version 0.1
 :
 :)

module "http://xqdev.com/prop"
declare namespace prop = "http://xqdev.com/prop"
default function namespace = "http://www.w3.org/2003/05/xpath-functions"


(:
	Can return a value of any one of the approved xs:* types.
	The type that is returned is denoted by the URI of the namespace.  For example:
	A uri of: http://xqdev.com/prop/boolean/true will return a boolean value set to true
	A uri of: http://xqdev.com/prop/string/true will return the string 'true'
:)
define function prop:get(
	$name as xs:string
) as xs:anySimpleType?
{
	try {
		let $uri := namespace-uri-for-prefix($name, element { concat($name, ":foo") } { () })
		let $bits := tokenize($uri, "/")
		let $type := $bits[5]
		let $value := xdmp:url-decode(string-join($bits[6 to count($bits)], "/"))
		where starts-with($uri, "http://xqdev.com/prop/")
		return 
			if($type = "string") then xs:string($value)
			else if($type = "boolean") then xs:boolean($value)
			else if($type = "decimal") then xs:decimal($value)
			else if($type = "float") then xs:float($value)
			else if($type = "double") then xs:double($value)
			else if($type = "duration") then xs:duration($value)
			else if($type = "dateTime") then xs:dateTime($value)
			else if($type = "time") then xs:time($value)
			else if($type = "date") then xs:date($value)
			else if($type = "gYearMonth") then xs:gYearMonth($value)
			else if($type = "gYear") then xs:gYear($value)
			else if($type = "gMonthDay") then xs:gMonthDay($value)
			else if($type = "gDay") then xs:gDay($value)
			else if($type = "gMonth") then xs:gMonth($value)
			else if($type = "hexBinary") then xs:hexBinary($value)
			else if($type = "base64Binary") then xs:base64Binary($value)
			else if($type = "QName") then xs:QName($value)
			else if($type = "integer") then xs:integer($value)
			else if($type = "nonPositiveInteger") then xs:nonPositiveInteger($value)
			else if($type = "negativeInteger") then xs:negativeInteger($value)
			else if($type = "long") then xs:long($value)
			else if($type = "int") then xs:int($value)
			else if($type = "short") then xs:short($value)
			else if($type = "byte") then xs:byte($value)
			else if($type = "nonNegativeInteger") then xs:nonNegativeInteger($value)
			else if($type = "unsignedLong") then xs:unsignedLong($value)
			else if($type = "unsignedInt") then xs:unsignedInt($value)
			else if($type = "unsignedShort") then xs:unsignedShort($value)
			else if($type = "unsignedByte") then xs:unsignedByte($value)
			else if($type = "positiveInteger") then xs:positiveInteger($value)
			else xs:string($value)
	}
	catch($e) {
		()
	}
}
