(:
 : lib-parser.xqy
 :
 : Copyright (c) 2003-2008 Mark Logic Corporation. All rights reserved.
 :
 :)

(:~
 : Mark Logic Search Parser.
 : This library module implements a Google-style search parser in XQuery.
 :
 : Coordinator:
 : @author <a href="mailto:michael.blakeley@marklogic.com">Michael Blakeley</a>
 :
 : Contributers (by last name):
 : @author <a href="mailto:William.LaForest@marklogic.com">William LaForest</a>
 : @author <a href="mailto:frank.rubino@marklogic.com">Frank Rubino</a>
 : @author <a href="mailto:chris.welch@marklogic.com">Chris Welch</a>
 :
 : @requires MarkLogic Server 3.2-1
 : Format: 3.2-YYYY-MM-DD.[Incremental]
 : @version 3.2-2008-05-06.1
 :
 :)
module "http://www.marklogic.com/ps/lib/lib-parser"

(: we don't want to have to prefix the fn:* functions :)
default function namespace = "http://www.w3.org/2003/05/xpath-functions"

declare namespace lp = "http://www.marklogic.com/ps/lib/lib-parser"
declare namespace qm = "http://marklogic.com/xdmp/query-meters"

import module
  namespace custom="http://www.marklogic.com/ps/lib/lib-parser-custom"
  at "lib-parser-custom.xqy"

(:~ QName for the cts:option element :)
define variable $CTS-OPTION as xs:QName { xs:QName("cts:option") }

(:~ QName for the cts:QName element :)
define variable $CTS-QNAME as xs:QName { xs:QName("cts:QName") }

(:~ @private :)
define variable $DEBUG as xs:boolean { false() }

(:~ default near-term distance weight, per docs :)
define variable $DEFAULT-DISTANCE as xs:integer { 100 }

(:~ default term weight, per docs :)
define variable $DEFAULT-WEIGHT as xs:double { 1.0 }

(:~ error code for unimplemented features :)
define variable $ERR-UNIMPLEMENTED as xs:string { "LP-UNIMPLEMENTED" }

(:~ error code for unexpected conditions :)
define variable $ERR-UNEXPECTED as xs:string { "LP-UNEXPECTED" }

(:~ error code for unexpected conditions :)
define variable $ERR-INVALID-QXML as xs:string { 'LP-INVALID-QUERY-XML' }

(:~ @private :)
define variable $UNIQUE-DELIM as xs:string { string(xdmp:random()) }

(:~ string containing the new-line character :)
define variable $NL as xs:string { codepoints-to-string(10) }

(:~ query-parser token for NOT operator :)
define variable $OP-NOT as cts:token { cts:word("NOT") }
define variable $OP-NOT-HYPHEN as cts:token { cts:punctuation('-') }
define variable $OP-NOTS as cts:token+ { $OP-NOT, $OP-NOT-HYPHEN }
(:~ query-parser token for OR operator :)
define variable $OP-OR as cts:token { cts:word("OR") }
define variable $OP-PIPE as cts:token { cts:punctuation("|") }
define variable $OP-ORS as cts:token+ { $OP-OR, $OP-PIPE }
(:~ query-parser token for AND operator, which will be ignored :)
define variable $OP-AND as cts:token { cts:word("AND") }
(:~ query-parser token for NEAR operator :)
define variable $OP-NEAR as cts:token { cts:word("NEAR") }

(:
 : fielded values with quotes are made more difficult,
 : because cts:tokenize treats ':"' as a single token.
 :)
(:~ query-parser token for field-specific search :)
define variable $OP-FIELD-WORD as cts:token { cts:punctuation(":") }
(:~ query-parser token for field-specific search :)
define variable $OP-FIELD-VALUE as cts:token { cts:punctuation("=") }

(:~ query-parser token for NEAR operator distance option :)
define variable $OP-NEAR-DISTANCE as cts:token { cts:punctuation("/") }

(:~ query-parser token for quoted phrases :)
define variable $OP-QUOTE as cts:token { cts:punctuation('"') }
(:~ query-parser token for start of grouping :)
define variable $OP-STARTGROUP as cts:token { cts:punctuation("(") }
(:~ query-parser token for end of grouping :)
define variable $OP-ENDGROUP as cts:token { cts:punctuation(")") }

(:~ query-parser token for whitespace :)
define variable $OP-SPACE as cts:token { cts:space(" ") }

(:~ query-parser prefix operator tokens :)
define variable $OPS-PREFIX as cts:token+ { $OP-NOTS }

(:~ query-parser infix operator tokens :)
define variable $OPS-INFIX as cts:token+ { $OP-ORS, $OP-AND, $OP-NEAR }

(:~ query-parser field-operator tokens :)
define variable $OPS-FIELD as cts:token+ { $OP-FIELD-WORD, $OP-FIELD-VALUE }

(:~ Query-parser default field-mappings for field-specific search.
 :  The qname attribute may contain any number of space-delimited values.
 :)
define variable $SEARCH-FIELD-MAP as element(lp:search-field-map) {
  <lp:search-field-map>
    <lp:mapping code="title" qname="title"/>
    <lp:mapping code="heading" qname="h1 h2 h3 h4 h5"/>
    <lp:mapping code="weighted" field="weighted"/>
  </lp:search-field-map>
}

(:-- DEBUGGING FUNCTIONS --:)

(:~ set debugging to true() or false() :)
define function lp:debug-set($debug as xs:boolean)
as empty() {
  xdmp:set($DEBUG, $debug)
}

(:~ turn debugging on :)
define function lp:debug-on() as empty() { xdmp:set($DEBUG, true()) }

(:~ turn debugging off :)
define function lp:debug-off() as empty() { xdmp:set($DEBUG, false()) }

(:~ if debugging is on, send a message to the error log :)
define function lp:debug($s as item()*)
as empty()
{
  if (not($DEBUG)) then () else
    xdmp:log(text { "DEBUG:",
      if (empty($s)) then "()" else
      for $i in $s return typeswitch($i)
        case node() return xdmp:quote($i)
        case cts:token return xdmp:quote($i)
        default return $i
    })
}

(:~ throw an error with the specified $code, using $s as supporting data. :)
define function lp:error($code as xs:string, $s as item()*)
 as empty()
{
  error($code, text {
    if (empty($s)) then "()" else
    for $i in $s return typeswitch ($i)
        case node() return xdmp:quote($i)
        case cts:token return xdmp:quote($i)
        default return $i
  } )
}

(:-- SEARCH METHODS --:)


(:~ Primary transformation methods for query strings. Pass a string, return a cts:query. :)
define function lp:get-cts-query
($qs as xs:string?) as cts:query?
{
  lp:get-cts-query($qs, (), ())
}

define function lp:get-cts-query
($qs as xs:string?, $map as element(lp:search-field-map)?)
 as cts:query?
{
  lp:get-cts-query($qs, $map, ())
}

define function lp:get-cts-query
($qs as xs:string?, $map as element(lp:search-field-map)?,
 $options as xs:string*)
 as cts:query?
{
  lp:deserialize-query(
    lp:get-cts-query-element($qs, $map), false(), $options)
}

define function lp:deserialize-query($q as node()*)
as cts:query*
{
  lp:deserialize-query($q, false(), ())
}

define function lp:deserialize-query(
  $q as node()*, $strict as xs:boolean)
as cts:query*
{
  lp:deserialize-query($q, $strict, ())
}

(:~ Use this method to convert a cts:query element to a cts:query value. :)
define function lp:deserialize-query(
  $q as node()*, $strict as xs:boolean, $options as xs:string*)
as cts:query*
{
  lp:debug(('lp:deserialize-query: ', $q, $strict, $options)),
  if ($strict) then lp:validate-query-xml($q) else (),
  lp:deserialize-query-R($q, $options)
}

define function lp:deserialize-query-R(
  $q as node()*, $options as xs:string*)
as cts:query*
{
  (: NB - this is our hot loop, for most work :)
  for $i as node() in $q return typeswitch($i)
    case document-node()
    return lp:deserialize-query-R($i/node(), $options)
    case comment()
    return ()
    case processing-instruction()
    return ()

    (: composite queries :)
    case element(cts:and-query)
    return cts:and-query(
      lp:deserialize-query-R(
        $i/node()[ node-name(.) ne $CTS-OPTION ], $options),
      $i/cts:option)
    case element(cts:near-query)
    return cts:near-query(
      lp:deserialize-query-R(
        $i/node()[ node-name(.) ne $CTS-OPTION ], $options),
      ($i/@distance, $DEFAULT-DISTANCE)[1],
      $i/cts:option,
      ($i/@weight, $DEFAULT-WEIGHT)[1] )
    case element(cts:or-query)
    return cts:or-query(
      lp:deserialize-query-R($i/node(), $options))

    case element(cts:not-query)
    return cts:not-query(
      lp:deserialize-query-R($i/node(), $options),
      ($i/@weight, $DEFAULT-WEIGHT)[1] )

    case element(cts:element-query)
    return cts:element-query(
      lp:deserialize-QNames($i/(@QName|cts:QName)),
      let $list := lp:deserialize-query-R(
        $i/node()[ not(node-name(.) = ($CTS-QNAME, $CTS-OPTION)) ],
        $options
      )
      return
        (: The empty and-query tests for presence of an element. :)
        if (exists($list)) then $list else cts:and-query(()),
      $i/cts:option
    )

    case element(cts:element-attribute-value-query)
    return custom:element-attribute-value-query(
      if (empty($i/(@element-QName|cts:element-QName)))
      then lp:error($ERR-UNEXPECTED, 'missing required element-QName')
      else lp:deserialize-QNames(
        $i/(@element-QName|cts:element-QName)
      ),
      if (empty($i/(@attribute-QName|cts:attribute-QName)))
      then lp:error($ERR-UNEXPECTED, 'missing required attribute-QName')
      else lp:deserialize-QNames(
        $i/(@attribute-QName|cts:attribute-QName)
      ),
      if ($i/cts:text) then $i/cts:text else $i/text(),
      lp:clean-search-options( ($i/cts:option, $options) ),
      ($i/@weight, $DEFAULT-WEIGHT)[1]
    )
    case element(cts:element-attribute-word-query)
    return custom:element-attribute-word-query(
      if (empty($i/(@element-QName|cts:element-QName)))
      then lp:error($ERR-UNEXPECTED, 'missing required element-QName')
      else lp:deserialize-QNames(
        $i/(@element-QName|cts:element-QName)
      ),
      if (empty($i/(@attribute-QName|cts:attribute-QName)))
      then lp:error($ERR-UNEXPECTED, 'missing required attribute-QName')
      else lp:deserialize-QNames(
        $i/(@attribute-QName|cts:attribute-QName)
      ),
      if ($i/cts:text) then $i/cts:text else $i/text(),
      lp:clean-search-options( ($i/cts:option, $options) ),
      ($i/@weight, $DEFAULT-WEIGHT)[1]
    )

    case element(cts:element-value-query)
    return custom:element-value-query(
      if (empty($i/(@QName|cts:QName)))
      then lp:error($ERR-UNEXPECTED, 'missing required element-QName')
      else lp:deserialize-QNames($i/(@QName|cts:QName)),
      if ($i/cts:text) then $i/cts:text else $i/text(),
      lp:clean-search-options( ($i/cts:option, $options) ),
      ($i/@weight, $DEFAULT-WEIGHT)[1]
    )
    case element(cts:element-word-query)
    return custom:element-word-query(
      if (empty($i/(@QName|cts:QName)))
      then lp:error($ERR-UNEXPECTED, 'missing required element-QName')
      else lp:deserialize-QNames($i/(@QName|cts:QName)),
      if ($i/cts:text) then $i/cts:text else $i/text(),
      lp:clean-search-options( ($i/cts:option, $options) ),
      ($i/@weight, $DEFAULT-WEIGHT)[1]
    )

    case element(cts:word-query)
    return custom:word-query(
      if ($i/cts:text) then $i/cts:text else $i/text(),
      lp:clean-search-options( ($i/cts:option, $options) ),
      ($i/@weight, $DEFAULT-WEIGHT)[1]
    )

    case element(cts:field-word-query)
    return custom:field-word-query(
      if (empty($i/(@string-item|cts:string-item)))
      then lp:error($ERR-UNEXPECTED, 'missing required field name as string')
      else lp:deserialize-strings($i/(@string-item|cts:string-item)),
      if ($i/cts:text) then $i/cts:text else $i/text(),
      lp:clean-search-options( ($i/cts:option, $options) ),
      ($i/@weight, $DEFAULT-WEIGHT)[1]
    )

    (: NB - in 4.0-EA2 this acts like a catchall :)
    case element(cts:query)
    return
      let $list := lp:deserialize-query-R($i/node(), $options)
      return
        if (count($list) lt 2) then $list else cts:and-query($list)

    (: Treat all whitespace as ignorable whitespace.
     : This is important when processing the output of xdmp:unquote.
     :)
    case text()
    return
      let $i := normalize-space($i)
      where $i ne ''
      return custom:word-query(
        $i, lp:clean-search-options($options), $DEFAULT-WEIGHT)
    default return custom:deserialize-custom-query($i, $options)
}

define function lp:get-cts-query-element
($qs as xs:string) as element(cts:query)?
{
  lp:get-cts-query-element($qs, ())
}

(:~ Primary parsing methods for query strings.
 : Pass a string, return a cts:query element.
 :)
(: Use these methods if a cts:query element has not already been constructed.
 : Use lp:serialize-cts-query if a cts:query already exists.
 :)
define function lp:get-cts-query-element($qs as xs:string?,
  $map as element(lp:search-field-map)?)
as element(cts:query)?
{
  (: Sadly, cts:tokenize() behavior differs from version to version.
   : For parser simplicity, we require each cts:punctuation() token
   : to contain a single character.
   :)
  let $toks :=
    if (number(substring-before(xdmp:version(), '-')) gt 3.1)
    then cts:tokenize(normalize-space($qs))
    else
      (: 3.1 coalesces adjacent punctuation characters,
       : so we have to split them up.
       :)
      for $t in cts:tokenize(normalize-space($qs))
      return
        if ($t instance of cts:punctuation and string-length($t) gt 1)
        then
          for $i in (1 to string-length($t))
          return cts:punctuation(substring($t, $i, 1))
        else $t
  (: if supplied, set the map :)
  let $map :=
    if (empty($map)) then () else xdmp:set($SEARCH-FIELD-MAP, $map)
  let $list := lp:parse-expr($toks, 1)
  let $d := lp:debug(("get-cts-query-element:", $list))
  where $list
  return element cts:query {
    if (count($list) gt 1)
    then element cts:and-query { $list }
    else $list
  }
}

(:~ get the text terms from one or more cts:query items :)
define function lp:terms-from-cts-query($q as cts:query*)
as xs:string*
{
  for $n in $q return typeswitch($n)
    case cts:and-not-query
    return lp:terms-from-cts-query((
      cts:and-not-query-positive-query($n),
      cts:and-not-query-negative-query($n) ))
    case cts:and-query
    return lp:terms-from-cts-query(cts:and-query-queries($n))
    case cts:not-query
    return lp:terms-from-cts-query(cts:not-query-query($n))
    case cts:or-query
    return lp:terms-from-cts-query(cts:or-query-queries($n))
    case cts:element-attribute-word-query
    return cts:element-attribute-word-query-text($n)
    case cts:element-attribute-value-query
    return cts:element-attribute-value-query-text($n)
    case cts:element-query
    return lp:terms-from-cts-query(cts:element-query-query($n))
    case cts:element-word-query
    return cts:element-word-query-text($n)
    case cts:element-value-query
    return cts:element-value-query-text($n)
    case cts:word-query
    return cts:word-query-text($n)
    case cts:field-word-query
    return cts:field-word-query-text($n)
    case cts:near-query
    return lp:terms-from-cts-query(cts:near-query-queries($n))
    (: collection query, registered query, et al :)
    default return ()
}

define function lp:validate-query-xml($q as node()*)
as empty()
{
  (: validate the structure of the query xml :)
  for $i in $q return typeswitch($i)
  case element(cts:query)
  return lp:validate-query-xml($i/node())

  (: composite queries :)
  case element(cts:and-query)
  return lp:validate-query-xml($i/node())
  case element(cts:or-query)
  return lp:validate-query-xml($i/node())
  case element(cts:near-query)
  return lp:validate-query-xml($i/node())
  case element(cts:not-query)
  return lp:validate-query-xml($i/node())
  case element(cts:and-not-query)
  return lp:validate-query-xml($i/node())
  case element(cts:element-query)
  return (
    lp:require-QName($i),
    lp:validate-query-xml(
      $i/node()[ not(node-name(.) = xs:QName("cts:QName")) ]) )

  (: metadata queries :)
  case element(cts:collection-query)
  return lp:validate-query-xml($i/node())
  case element(cts:directory-query)
  return lp:validate-query-xml($i/node())
  case element(cts:document-query)
  return lp:validate-query-xml($i/node())

  (: simple queries :)
  case element(cts:element-attribute-value-query)
  return lp:require-text($i)
  case element(cts:element-attribute-word-query)
  return ( lp:require-QName($i), lp:require-text($i) )
  case element(cts:element-value-query)
  return ( lp:require-QName($i), lp:require-text($i) )
  case element(cts:element-word-query)
  return ( lp:require-QName($i), lp:require-text($i) )
  case element(cts:field-word-query)
  return ( lp:require-string($i), lp:require-text($i) )
  case element(cts:word-query)
  return lp:require-text($i)
  case text()
  return lp:forbid-text($i)
  default return lp:error(
    $ERR-INVALID-QXML,
    text { 'unhandled node type:', xdmp:describe($i) } )
}

(:~ @private :)
define function lp:require-text($n as element())
 as empty()
{
  if (normalize-space($n) ne '') then () else
  lp:error(
    $ERR-INVALID-QXML,
    text { local-name($n), "must include text" } )
}

(:~ @private :)
define function lp:forbid-text($n as node())
 as empty()
{
  if (normalize-space($n) eq '') then () else
  lp:error(
    $ERR-INVALID-QXML,
    text { node-kind($n), "must not include non-whitespace text" } )
}

(:~ @private :)
define function lp:require-QName($n as node())
 as empty()
{
  if ($n/cts:QName) then () else
  lp:error(
    $ERR-INVALID-QXML,
    text { "QName element required in ", xdmp:quote($n) } )
}

(:~ @private :)
define function lp:require-string($n as node())
 as empty()
{
  if ($n/cts:string-item) then () else
  lp:error(
    $ERR-INVALID-QXML,
    text { "string-item element required in ", xdmp:quote($n) } )
}

(:~ serialize a cts:query as xml :)
define function lp:serialize-cts-query($q as cts:query*)
as element()*
{
  lp:debug(('serialize-cts-query:', $q)),
  let $list := lp:serialize-cts-queries($q)
  where $list
  return element cts:query { $list }
}

(:-- Private Functions --:)

(:~ @private :)
define function lp:serialize-cts-queries($q as cts:query*)
as element()*
{
  lp:debug(('serialize-cts-queries:', $q)),
  for $t in $q return typeswitch($t)
    case cts:and-query
    return element cts:and-query {
      lp:serialize-cts-queries(cts:and-query-queries($t)) }
    case cts:or-query
    return element cts:or-query {
      lp:serialize-cts-queries(cts:or-query-queries($t)) }
    case cts:not-query
    return element cts:not-query {
      attribute weight { cts:not-query-weight($t) },
      lp:serialize-cts-queries(cts:not-query-query($t)) }
    case cts:near-query
    return element cts:near-query {
      attribute distance { cts:near-query-distance($t) },
      attribute weight { cts:near-query-weight($t) },
      lp:serialize-cts-queries(cts:near-query-queries($t)) }
    case cts:element-attribute-value-query
    return element cts:element-attribute-value-query {
      attribute weight { cts:element-attribute-value-query-weight($t) },
      for $qn in cts:element-attribute-value-query-element-name($t)
      return lp:serialize-QNames($qn, 'element-QName'),
      for $qn in cts:element-attribute-value-query-attribute-name($t)
      return lp:serialize-QNames($qn, 'attribute-QName'),
      for $i in cts:element-attribute-value-query-text($t)
      return element cts:text { $i },
      for $o in cts:element-attribute-value-query-options($t)
      return element cts:option { $o } }
    case cts:element-attribute-word-query
    return element cts:element-attribute-word-query {
      attribute weight { cts:element-attribute-word-query-weight($t) },
      for $qn in cts:element-attribute-word-query-element-name($t)
      return lp:serialize-QNames($qn, 'element-QName'),
      for $qn in cts:element-attribute-word-query-attribute-name($t)
      return lp:serialize-QNames($qn, 'attribute-QName'),
      for $i in cts:element-attribute-word-query-text($t)
      return element cts:text { $i },
      for $o in cts:element-attribute-word-query-options($t)
      return element cts:option { $o } }
    case cts:element-query
    return element cts:element-query {
      lp:serialize-QNames(cts:element-query-element-name($t)),
      lp:serialize-cts-queries(cts:element-query-query($t)) }
    case cts:element-value-query
    return element cts:element-value-query {
      attribute weight { cts:element-value-query-weight($t) },
      lp:serialize-QNames(cts:element-value-query-element-name($t)),
      for $i in cts:element-value-query-text($t)
      return element cts:text { $i },
      for $o in cts:element-value-query-options($t)
      return element cts:option { $o } }
    case cts:element-word-query
    return element cts:element-word-query {
      attribute weight { cts:element-word-query-weight($t) },
      lp:serialize-QNames(cts:element-word-query-element-name($t)),
      for $i in cts:element-word-query-text($t)
      return element cts:text { $i },
      for $o in cts:element-word-query-options($t)
      return element cts:option { $o } }
    case cts:word-query
    return element cts:word-query {
      attribute weight { cts:word-query-weight($t) },
      for $i in cts:word-query-text($t)
      return element cts:text { $i },
      for $o in cts:word-query-options($t)
      return element cts:option { $o } }
    case cts:field-word-query
    return element cts:field-word-query {
      lp:serialize-strings( cts:field-word-query-field-name($t)),
      attribute weight {  cts:field-word-query-weight($t) },
      for $i in cts:field-word-query-text($t)
      return element cts:text { $i },
      for $o in  cts:field-word-query-options($t)
      return element cts:option { $o } }

    default return lp:error($ERR-UNIMPLEMENTED, ("cts:query", $t))
}

(:~ @private :)
define function lp:serialize-QNames($list as xs:QName*)
as element()*
{
  lp:serialize-QNames($list, 'QName')
}

(:~ @private :)
define function lp:serialize-QNames($list as xs:QName*, $lname as xs:string)
as element()*
{
  lp:debug(('serialize-QNames:', $list, 'as', $lname)),
  for $qn in $list
  return element { concat('cts:', $lname) } {
    let $ns := namespace-uri-from-QName($qn)
    where $ns ne ''
    return attribute namespace-uri { $ns },
    local-name-from-QName($qn)
  }
}

(:~ @private :)
define function lp:deserialize-QNames($nodes as node()+)
 as item()+
{
  lp:debug(('lp:deserialize-QNames:', $nodes)),
  for $n in $nodes
  return
    if (not(local-name($n) = ('QName', 'element-QName', 'attribute-QName')))
    then lp:error($ERR-UNEXPECTED, ($n))
    else if (contains($n, ':')) then lp:error($ERR-UNEXPECTED, ($n))
    else if ($n/@namespace-uri) then QName($n/@namespace-uri, $n)
    else xs:QName($n)
}

(:~ @private :)
define function lp:serialize-strings($list as xs:string*)
as element()*
{
  lp:debug(('serialize-strings:', $list)),
  for $s in $list
  return element cts:string-item {
    $s
  }
}

(:~ @private :)
define function lp:deserialize-strings($nodes as node()+)
 as item()+
{
  lp:debug(('lp:deserialize-strings:', $nodes)),
  for $n in $nodes
  return
    if (not(local-name($n) = ('string-item')))
    then lp:error($ERR-UNEXPECTED, ($n))
    else xs:string($n)
}


(:~ @private :)
define function lp:find-next-op($toks as cts:token*, $ops as cts:token+)
 as xs:integer?
{
  if (empty($toks)) then () else
  let $tag := "find-next-op:"
  let $d :=
    lp:debug(($tag, count($toks), "toks =", $toks, ", ops =", $ops))
  where $toks[. = $ops][1]
  return
    let $op := $toks[. = $ops][1]
    let $pos := index-of($toks, $op)[1]
    let $d := lp:debug(($tag, "pos =", $pos, ", op =", $toks[$pos]))
    return $pos
}

(:~ @private :)
define function lp:next-word($toks as cts:token+)
as item()+
{
  lp:next-word($toks, false())
}

(:~ @private :)
define function lp:next-word($toks as cts:token+, $field as xs:boolean)
as item()+
{
  let $pos := lp:find-next-op(
    $toks,
    ($OP-SPACE, $OPS-FIELD[not($field)], $OP-STARTGROUP, $OP-ENDGROUP)
  )
  let $d := lp:debug(("next-word: toks =", $toks, ", pos =", $pos))
  return
    if ($pos)
    then ($pos - 1, string-join(subsequence($toks, 1, $pos - 1), ''))
    else (count($toks), string-join($toks, ''))
}

(:~ @private :)
(: find the end of the quoted-string,
 : or the end of the expr, if unbalanced
 :)
define function lp:next-quoted-word($toks as cts:token+)
as item()+
{
  (: don't include the end-quote in the literal :)
  let $quote :=
    ($toks[ . instance of cts:punctuation ][ contains(., $OP-QUOTE) ])[1]
  let $len := if ($quote) then index-of($toks, $quote)[1] - 1 else ()
  let $pos := if ($len) then (1 + $len) else count($toks)
  let $d := lp:debug((
    "next-quoted-word:", "toks =", $toks, ", len =", $len, ", pos =", $pos ))
  let $final := (
    $pos,
    string-join(
      if (exists($len)) then subsequence($toks, 1, $len) else $toks, '')
  )
  let $d := lp:debug(("next-quoted-word:", "final =", $final))
  return $final
}

(:~ @private :)
(: find the end of the string or quoted-string.
 :)
define function lp:next-literal($toks as cts:token+)
as item()*
{
  lp:next-literal($toks, false())
}

(:~ @private :)
(: find the end of the string or quoted-string.
 :)
define function lp:next-literal($toks as cts:token+, $field as xs:boolean)
as item()*
{
  lp:debug(("next-literal: field =", $field, "toks =", $toks)),
  if (empty($toks)) then ()
  else if ($toks[1] eq $OP-QUOTE)
  then
    let $literal := lp:next-quoted-word(subsequence($toks, 2))
    return (1 + $literal[1], $literal[2])
  else lp:next-word($toks, $field)
}

(:~ @private :)
(: Note that we ignore unmapped field names!
 :)
define function lp:next-field-term($field as xs:string, $toks as cts:token+)
as item()+
{
  let $d :=
    lp:debug(("next-field-term: field =", $field, "toks =", $toks))
  (: skip past the operator :)
  let $pos := 1
  let $op := $toks[ $pos ]
  let $toks := subsequence($toks, 1 + $pos)
  (: NB there may not be another tok :)
  let $literal :=
    if (exists($toks)) then lp:next-literal($toks, true()) else 0
  let $d := lp:debug(("next-field-term: value literal =", $literal))
  let $pos := $pos + $literal[1]
  let $value := $literal[2]
  let $d := lp:debug((
    "next-field-term:", "pos = ", $pos,
    "field =", $field, ", op =", $op, ", value =", $value))
  return (
    $pos,
    (: there may be multiple mappings, or none :)
    for $mapping in $SEARCH-FIELD-MAP/lp:mapping[ @code eq $field ]
    let $d := lp:debug(("next-field-term: mapping =", $mapping))
    (: handle operator override by reversing the logic :)
    let $type :=
      (:3.2 field-word-query support :)
      (:this mapping will either have qname or field attributes :)
      (:if the qname attributes exist, create element queries:)
      (:if field attributes exist, create field-word queries :)
      if(exists($mapping/@field[1])) then
        "cts:field-word-query"
      else
        if (empty($value)) then "cts:element-query"
       else concat(
         "cts:element-",
          if ($op eq $OP-FIELD-WORD) then "word" else "value",
          "-query"
        )


    (: mappings may be encoded as qname attributes, field attributes (for 3.2 fields):)
    (: or as empty elements :)
    let $name-nodes := (
      $mapping/*,
      for $n in (tokenize($mapping/@qname, '\s+'))
      return element { $n } {}
    )

    return
    element { $type } {
      (:3.2 field-word-query support:)
      (:we'll either have qname or field attrs:)
      lp:serialize-QNames(for $n in $name-nodes return node-name($n)),
      for $f in tokenize($mapping/@field, '\s+')
      return element cts:string-item {fn:data($f)},
      if (empty($mapping/@options)) then () else
      for $o in xs:NMTOKENS($mapping/@options)
      return element cts:option { $o },
      $value
    }
  )
}

(:~ @private :)
define function lp:next-term($toks as cts:token*)
as item()+
{
  lp:debug(("next-term: toks =", $toks)),
  if (empty($toks)) then 0
  else if ($toks[1] eq "'")
  then
    let $term := lp:next-term(subsequence($toks, 2))
    return (1 + $term[1], subsequence($term, 2))
  else
    let $literal := lp:next-literal($toks)
    let $d := lp:debug(("next-term: literal =", $literal))
    let $pos := $literal[1]
    let $toks := subsequence($toks, 1 + $pos)
    return
      if ($toks[1] = $OPS-FIELD)
      then
        let $term := lp:next-field-term($literal[2], $toks)
        return ($pos + $term[1], $term[2])
      else ($literal[1], element cts:word-query { $literal[2] })
}

(:~ @private :)
define function lp:next-group($toks as cts:token*, $depth as xs:integer)
as item()*
{
  lp:debug(("next-group: toks =", $toks)),
  if (empty($toks)) then ()
  else if ($toks[1] eq $OP-ENDGROUP)
  (: NB: no elements - just consume the token :)
  then 1
  else if ($toks[1] eq $OP-STARTGROUP)
  then
    (: a group can have any expr inside it, so we have to recurse it :)
    let $pos := lp:find-next-op($toks, $OP-ENDGROUP)
    (: if a paren is left dangling, go to the end :)
    let $pos :=
      if ($pos) then $pos else count($toks)
    return (
      $pos,
      (: remember to skip the open-paren :)
      let $list :=
        lp:parse-expr(subsequence($toks, 2, $pos - 1), 1 + $depth)
      return
        if (count($list) lt 2)
        then $list
        else element cts:and-query { $list }
    )
  else lp:next-term($toks)
}

(: TODO implement range per google, field:\d+\.\.\d+ :)

(:~ @private :)
define function lp:parse-expr($toks as cts:token*, $depth as xs:integer)
as item()*
{
  let $tag := concat('parse-expr-', string($depth), ':')
  (: this is rather expensive to keep active :)
  (: let $d := lp:debug(($tag, "toks =", xdmp:describe($toks))) :)
  return
    if (empty($toks)) then ()
    else if ($toks[1] eq $OP-SPACE)
    then lp:parse-expr(subsequence($toks, 2), 1 + $depth)
    (: prefix notation :)
    else if ($toks[1] = $OPS-PREFIX)
    then
      if ($toks[1] = $OP-NOTS) then
        let $d := lp:debug(($tag, "op-not"))
        (: handle the various $OP-NOTS, and trim any leading space :)
        let $toks :=
          subsequence($toks, if ($toks[2] eq $OP-SPACE) then 3 else 2)
        let $group := lp:next-group($toks, $depth)
        where $group
        return
          let $pos := $group[1]
          let $toks := subsequence($toks, 1 + $pos)
          let $toks :=
            if ($toks[1] eq $OP-SPACE) then subsequence($toks, 2) else $toks
          let $qe := element cts:not-query { $group[2] }
          return ($qe, lp:parse-expr($toks, 1 + $depth))
      else lp:error($ERR-UNEXPECTED, $toks)
    (: infix notation - or an isolated group :)
    else
      let $d := lp:debug(($tag, "infix"))
      let $group := lp:next-group($toks, $depth)
      where $group
      return
        let $pos := $group[1]
        let $toks := subsequence($toks, 1 + $pos)
        let $toks :=
          if ($toks[1] eq $OP-SPACE) then subsequence($toks, 2) else $toks
        return
          if (not($toks[1] = $OPS-INFIX))
          then (
            lp:debug(($tag, "group", $group)),
            $group[2],
            lp:parse-expr($toks, 1 + $depth)
          )
          else
            let $op := $toks[1]
            let $d := lp:debug(($tag, "infix op =", $op))
            return
              if ($op = $OP-ORS)
              then
                let $expr :=
                  lp:parse-expr(subsequence($toks, 2), 1 + $depth)
                let $group-b := $expr[1]
                let $expr := subsequence($expr, 2)
                return (element cts:or-query { $group[2], $group-b }, $expr)
              else if ($op eq $OP-AND)
              then
                (: ignore it and move on :)
                ($group[2], lp:parse-expr(subsequence($toks, 2), 1 + $depth))
              else if ($op eq $OP-NEAR)
              then
                if ($toks[2] eq $OP-NEAR-DISTANCE
                  and $toks[3] castable as xs:integer)
                then
                  let $distance := xs:integer($toks[3])
                  let $d :=
                    lp:debug(($tag, 'extracting distance', $distance))
                  let $expr :=
                    lp:parse-expr(subsequence($toks, 4), 1 + $depth)
                  let $group-b := $expr[1]
                  let $expr := subsequence($expr, 2)
                  return (
                    element cts:near-query {
                      attribute distance { $distance }, $group[2], $group-b
                    },
                    $expr
                  )
                else
                  let $expr :=
                    lp:parse-expr(subsequence($toks, 2), 1 + $depth)
                  let $group-b := $expr[1]
                  let $expr := subsequence($expr, 2)
                  return
                    (element cts:near-query { $group[2], $group-b }, $expr)
              else lp:error($ERR-UNEXPECTED, $toks)
}

(:~ @private :)
define function lp:clean-search-options($options as xdt:anyAtomicType*)
 as xs:string*
{
  if (empty($options)) then ()
  else distinct-values(
    for $option in $options
    return normalize-space(lower-case(string($option)))
  )
}

(: lib-parser.xqy :)