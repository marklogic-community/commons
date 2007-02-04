module "http://marklogic.com/json"
declare namespace json="http://marklogic.com/json"
default function namespace = "http://www.w3.org/2003/05/xpath-functions"

(: Need to backslash escape any double quotes and backslashes :)
define function json:escape($s as xs:string) as xs:string {
  let $s := replace($s, "\\", "\\")
  let $s := replace($s, """", "\""")
  return $s
}

define function json:atomize($x as element()) as xs:string {
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
}

(: Print the thing that comes after the colon :)
define function json:print-value($x as element()) as xs:string {
  if (count($x/*) = 0) then
    json:atomize($x)
  else
    string-join(('{',
      string-join(for $i in $x/* return json:print-name-value($i), ","),
    '}'), "")
}

(: Print the name and value both :)
define function json:print-name-value($x as element()) as xs:string? {
  let $name := name($x)
  let $first-in-array :=
    count($x/preceding-sibling::*[name(.) = $name]) = 0 and
    (count($x/following-sibling::*[name(.) = $name]) > 0 or $x/@array = "true")
  let $later-in-array := count($x/preceding-sibling::*[name(.) = $name]) > 0
  return

  if ($later-in-array) then
    ()  (: I was handled previously :)
  else if ($first-in-array) then
    string-join(('"', json:escape($name), '":[',
      string-join((for $i in ($x, $x/following-sibling::*[name(.) = $name]) return json:print-value($i)), ","),
    ']'), "")
  else
    string-join(('"', json:escape($name), '":', json:print-value($x)), "")
}

(:~
  Transforms an XML element into a JSON string representation.  See http://json.org.
  <p/>
  Sample usage:
  <pre>
    import module namespace json="http://marklogic.com/json" at "json.xqy"
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
  </pre>
  <p/>
  Namespace URIs are ignored.  Namespace prefixes are included in the JSON name.
  <p/>
  Attributes are ignored, except for the special attribute @array="true" that
  indicates the JSON serialization should write the node, even if single, as an
  array, and the attribute @type that can be set to "boolean" or "number" to
  dictate the value should be written as that type (unquoted).
  <p/>
  Text nodes within mixed content are ignored.

  @param $x Element node to convert
  @return String holding JSON serialized representation of $x

  @author Jason Hunter
  @version 1.0
:)
define function json:serialize($x as element())  as xs:string {
  string-join(('{', json:print-name-value($x), '}'), "")
}
