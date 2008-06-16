(:
 : lib-parser-custom.xqy
 :
 : Copyright (c) 2003-2007 Mark Logic Corporation. All rights reserved.
 :
 :)

(:~
 : Custom handler for Mark Logic Search Parser.
 : This library allows for serialization and deserialization
 : of custom query elements.
 :
 :)
module "http://www.marklogic.com/ps/lib/lib-parser-custom"

import module namespace lp = "http://www.marklogic.com/ps/lib/lib-parser"
  at "lib-parser.xqy"

(: we don't want to have to prefix the fn:* functions :)
default function namespace = "http://www.w3.org/2003/05/xpath-functions"

declare namespace custom = "http://www.marklogic.com/ps/lib/lib-parser-custom"

define function custom:element-attribute-value-query(
  $element-name as xs:QName*,
  $attribute-name as xs:QName*,
  $text as xs:string*,
  $options as xs:string*,
  $weight as xs:double
) as cts:query {
  cts:element-attribute-value-query(
    $element-name,
    $attribute-name,
    $text,
    $options,
    $weight
  )
}

define function custom:element-attribute-word-query(
  $element-name as xs:QName*,
  $attribute-name as xs:QName*,
  $text as xs:string*,
  $options as xs:string*,
  $weight as xs:double
) as cts:query {
  cts:element-attribute-word-query(
    $element-name,
    $attribute-name,
    $text,
    $options,
    $weight
  )
}

define function custom:element-value-query(
  $element-name as xs:QName*,
  $text as xs:string*,
  $options as xs:string*,
  $weight as xs:double
) as cts:query {
  cts:element-value-query(
    $element-name,
    $text,
    $options,
    $weight
  )
}

define function custom:element-word-query(
  $element-name as xs:QName*,
  $text as xs:string*,
  $options as xs:string*,
  $weight as xs:double
) as cts:query {
  cts:element-word-query(
    $element-name,
    $text,
    $options,
    $weight
  )
}

define function custom:word-query(
  $text as xs:string*,
  $options as xs:string*,
  $weight as xs:double
) as cts:query {
  cts:word-query($text, $options, $weight)
}

define function custom:field-word-query(
  $field-names as xs:string*,
  $text as xs:string*,
  $options as xs:string*,
  $weight as xs:double
) as cts:query {
  cts:field-word-query(
    $field-names,
    $text,
    $options,
    $weight
  )
}

(:~ Use this method to deserialize custom elements in a cts:query element :)
define function custom:deserialize-custom-query(
  $q as node()*, $options as xs:string*)
 as cts:query*
{
  (: best practice - throw an error as the default action :)
  lp:error($lp:ERR-UNIMPLEMENTED, $q)
}

(: lib-parser-custom.xqy :)
