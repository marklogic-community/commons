(:~
 :
 : Copyright 2011 Ryan Grimm
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
 : these namespaces as key value pairs.
 :
 : Note: Properties are visible to the entire application group inside of
 : MarkLogic.  That means that a property that is set in one app server will be
 : visible to all the app servers in the same group.
 : 
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
 : @version 0.2
 :
 :)

xquery version "1.0-ml";

module namespace prop="http://xqdev.com/prop";
import module namespace admin = "http://marklogic.com/xdmp/admin" at "/MarkLogic/admin.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

(:~
 : Sets a property.
 :
 : Note: Properties are visible to the entire application group inside of
 : MarkLogic.  That means that a property that is set in one app server will be
 : visible to all the app servers in the same group.
 :
 : $key - The property key.  Must be unique.
 : $value - The property value can be of any simple type:
 : xs:string, xs:boolean, xs:decimal, xs:float, xs:double, xs:duration,
 : xs:dateTime, xs:time, xs:date, xs:gYearMonth, xs:gYear, xs:gMonthDay, xs:gDay
 : xs:gMonth, xs:hexBinary, xs:base64Binary, xs:QName, xs:integer,
 : xs:nonPositiveInteger, xs:negativeInteger, xs:long, xs:int, xs:short, xs:byte,
 : xs:nonNegativeInteger, xs:unsignedLong, xs:unsignedInt, xs:unsignedShort,
 : xs:unsignedByte, xs:positiveInteger
 :
 :)
declare function prop:set(
    $key as xs:string,
    $value as xs:anySimpleType
) as empty-sequence()
{
    let $config := admin:get-configuration()
    let $group := xdmp:group()
    let $existing := admin:group-get-namespaces($config, $group)[*:prefix = $key]
    let $test :=
        if(exists($existing))
        then error("PROP:REDEFINE-PROPERTY", concat("A property with the key ", $key, " already exists"))
        else ()

    let $type :=
        if($value instance of xs:string) then "string"
        else if($value instance of xs:boolean) then "boolean"
        else if($value instance of xs:decimal) then "decimal"
        else if($value instance of xs:float) then "float"
        else if($value instance of xs:double) then "double"
        else if($value instance of xs:duration) then "duration"
        else if($value instance of xs:dateTime) then "dateTime"
        else if($value instance of xs:time) then "time"
        else if($value instance of xs:date) then "date"
        else if($value instance of xs:gYearMonth) then "gYearMonth"
        else if($value instance of xs:gYear) then "gYear"
        else if($value instance of xs:gMonthDay) then "gMonthDay"
        else if($value instance of xs:gDay) then "gDay"
        else if($value instance of xs:gMonth) then "gMonth"
        else if($value instance of xs:hexBinary) then "hexBinary"
        else if($value instance of xs:base64Binary) then "base64Binary"
        else if($value instance of xs:QName) then "QName"
        else if($value instance of xs:integer) then "integer"
        else if($value instance of xs:nonPositiveInteger) then "nonPositiveInteger"
        else if($value instance of xs:negativeInteger) then "negativeInteger"
        else if($value instance of xs:long) then "long"
        else if($value instance of xs:int) then "int"
        else if($value instance of xs:short) then "short"
        else if($value instance of xs:byte) then "byte"
        else if($value instance of xs:nonNegativeInteger) then "nonNegativeInteger"
        else if($value instance of xs:unsignedLong) then "unsignedLong"
        else if($value instance of xs:unsignedInt) then "unsignedInt"
        else if($value instance of xs:unsignedShort) then "unsignedShort"
        else if($value instance of xs:unsignedByte) then "unsignedByte"
        else if($value instance of xs:positiveInteger) then "positiveInteger"
        else "string"

    let $namespace := admin:group-namespace($key, concat("http://xqdev.com/prop/", $type, "/", $value))
    return admin:save-configuration(admin:group-add-namespace($config, $group, $namespace))
};

(:~
 : Deletes a property. If there isn't a property with the supplied $key, no action is performed.
 :)
declare function prop:delete(
    $key as xs:string
) as empty-sequence()
{
    let $config := admin:get-configuration()
    let $group := xdmp:group()
    let $namespace := admin:group-get-namespaces($config, $group)[*:prefix = $key]
    where exists($namespace)
    return admin:save-configuration(admin:group-delete-namespace($config, $group, $namespace))
};


(:~
 : Returns the value of the property for $key. The return type is cast as the
 : same type when the property was set.
 :)
declare function prop:get(
	$key as xs:string
) as xs:anySimpleType?
{
	try {
		let $uri := namespace-uri-for-prefix($key, element { concat($key, ":foo") } { () })
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
};

declare function prop:all(
) as xs:string*
{
    let $config := admin:get-configuration()
    for $ns in admin:group-get-namespaces($config, xdmp:group())
    where starts-with($ns/*:namespace-uri, "http://xqdev.com/prop/")
    return string($ns/*:prefix)
};
