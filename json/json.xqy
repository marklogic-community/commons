xquery version "1.0-ml";

(: Copyright 2006-2010 Mark Logic Corporation. :)

(:
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
 :)

module namespace json = "http://marklogic.com/json";
declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare variable $new-line-regex := concat('[',codepoints-to-string((13, 10)),']+');
declare variable $tab-regex := codepoints-to-string(9);

(: Need to backslash escape any double quotes, backslashes, newlines and tabs :)
declare function json:escape($s as xs:string) as xs:string {
  let $s := replace($s, "(\\|"")", "\\$1")
  let $s := replace($s, $new-line-regex, "\\n")
  let $s := replace($s, $tab-regex, "\\t")
  return $s
};

declare function json:atomize($x as element()) as xs:string {
  if (count($x/node()) = 0) then 'null'
  else if ($x/@type = "number") then
    let $castable := $x castable as xs:float or
                     $x castable as xs:double or
                     $x castable as xs:decimal
    return
    if ($castable) then xs:string($x)
    else error(concat("Not a number: ", xdmp:describe($x)))
  else if ($x/@type = "boolean") then
    let $castable := $x castable as xs:boolean
    return
    if ($castable) then xs:string(xs:boolean($x))
    else error(concat("Not a boolean: ", xdmp:describe($x)))
  else concat('"', json:escape($x), '"')
};

(: Print the thing that comes after the colon :)
declare function json:print-value($x as element()) as xs:string {
  if (count($x/*) = 0) then
    json:atomize($x)
  else if ($x/@quote = "true") then
    concat('"', json:escape(xdmp:quote($x/node())), '"')
  else
    string-join(('{',
      string-join(for $i in $x/* return json:print-name-value($i), ","),
    '}'), "")
};

(: Print the name and value both :)
declare function json:print-name-value($x as element()) as xs:string? {
  let $node-name := node-name($x)
  let $later-in-array := exists($x/following-sibling::*[node-name(.) = $node-name])
  return
  if ($later-in-array) then
    ()  (: I am going to be handled later :)
  else 
	let $preceding-siblings := $x/preceding-sibling::*[node-name(.) = $node-name]
	let $last-in-array := ($x/@array = "true" or exists($preceding-siblings))
	return if ($last-in-array) then
         	string-join(('"', xs:string($node-name), '":[',
      		   string-join((for $i in ($preceding-siblings, $x) return json:print-value($i)), ","),
    	     ']'), "")
   		   else
             string-join(('"', xs:string($node-name), '":', json:print-value($x)), "")
};

(:~
  Transforms an XML element into a JSON string representation.  See http://json.org.
  <p/>
  Sample usage:
  <pre>
    xquery version "1.0-ml";
    import module namespace json="http://marklogic.com/json" at "json.xqy";
    json:serialize(&lt;foo&gt;&lt;bar&gt;kid&lt;/bar&gt;&lt;/foo&gt;)
  </pre>
  Sample transformations:
  <pre>
  &lt;e/&gt; becomes {"e":null}
  &lt;e&gt;text&lt;/e&gt; becomes {"e":"text"}
  &lt;e&gt;quote " escaping&lt;/e&gt; becomes {"e":"quote \" escaping"}
  &lt;e&gt;backslash \ escaping&lt;/e&gt; becomes {"e":"backslash \\ escaping"}
  &lt;e&gt;&lt;a&gt;text1&lt;/a&gt;&lt;b&gt;text2&lt;/b&gt;&lt;/e&gt; becomes {"e":{"a":"text1","b":"text2"}}
  &lt;e&gt;&lt;a&gt;text1&lt;/a&gt;&lt;a&gt;text2&lt;/a&gt;&lt;/e&gt; becomes {"e":{"a":["text1","text2"]}}
  &lt;e&gt;&lt;a array="true"&gt;text1&lt;/a&gt;&lt;/e&gt; becomes {"e":{"a":["text1"]}}
  &lt;e&gt;&lt;a type="boolean"&gt;false&lt;/a&gt;&lt;/e&gt; becomes {"e":{"a":false}}
  &lt;e&gt;&lt;a type="number"&gt;123.5&lt;/a&gt;&lt;/e&gt; becomes {"e":{"a":123.5}}
  &lt;e quote="true"&gt;&lt;div attrib="value"/&gt;&lt;/e&gt; becomes {"e":"&lt;div attrib=\"value\"/&gt;"}
  </pre>
  <p/>
  Namespace URIs are ignored.  Namespace prefixes are included in the JSON name.
  <p/>
  Attributes are ignored, except for the special attribute @array="true" that
  indicates the JSON serialization should write the node, even if single, as an
  array, and the attribute @type that can be set to "boolean" or "number" to
  dictate the value should be written as that type (unquoted).  There's also
  an @quote attribute that when set to true writes the inner content as text
  rather than as structured JSON, useful for sending some XHTML over the
  wire.
  <p/>
  Text nodes within mixed content are ignored.

  @param $x Element node to convert
  @return String holding JSON serialized representation of $x

  @author Jason Hunter
  @version 1.0.1
  
  Ported to xquery 1.0-ml; double escaped backslashes in json:escape
:)
declare function json:serialize($x as element())  as xs:string {
  string-join(('{', json:print-name-value($x), '}'), "")
};

