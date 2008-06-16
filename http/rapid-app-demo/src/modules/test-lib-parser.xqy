(:
 : test-lib-parser.xqy
 :
 : Copyright (c) 2003-2007 Mark Logic Corporation. All rights reserved.
 :
 :)

(:~
 : Mark Logic Search Parser unit tests.
 : Unit tests for lib-parser that can be executed via invoke.
 :
 : Contributers (by last name):
 : @author <a href="mailto:michael.blakeley@marklogic.com">Michael Blakeley</a>
 : @author <a href="mailto:shivaji.dutta@marklogic.com">Shivaji Dutta</a>
 : @author <a href="mailto:james.kerr@makrlogic.com">James Kerr</a>
 : @author <a href="mailto:William.LaForest@marklogic.com">William LaForest</a>
 : @author <a href="mailto:shashi.mudunuri@marklogic.com">Shashi Mudunuri</a>
 : @author <a href="mailto:frank.rubino@marklogic.com">Frank Rubino</a>
 : @author <a href="mailto:chris.welch@marklogic.com">Chris Welch</a>
 : @author <a href="mailto:colleen.whitney@marklogic.com">Colleen Whitney</a>
 :
 : @requires lib-parser.xqy
 : @requires the following 3.2 Mark Logic fields: foo bar weighted
 :
 :)

import module namespace p="http://www.marklogic.com/ps/lib/lib-parser"
  at "lib-parser.xqy"

define variable $IMPORT-MODULE as xs:string {
'import module namespace p="http://www.marklogic.com/ps/lib/lib-parser"
  at "lib-parser.xqy"' }

(:-- TEST METHODS --:)

define function test($expected as item()*, $actual as item()*,
 $raw as item()?)
as xdt:anyAtomicType
{
  (: deep-equal doesn't work with cts:query items,
   : so we do extra work - bug 3287.
   :)
  let $query := max((
    for $i in ($expected, $actual)
    return $i instance of cts:query
    ))
  return
    if (($query and xdmp:quote($actual) eq xdmp:quote($expected))
      or (not($query) and deep-equal($actual, $expected)))
    then true()
    else concat("ERROR! ",
      if (empty($raw)) then () else concat(xdmp:quote($raw), ": "),
      if (empty($actual)) then "()" else xdmp:quote($actual),
      " ne ", xdmp:quote($expected))
}

define function test($test as element(test))
as xdt:anyAtomicType
{
  let $options :=
    <options xmlns="xdmp:eval">
      <isolation>different-transaction</isolation>
    </options>
  let $expected := $test/expected/node()
  (: is the expected-value an xquery that we must evaluate? :)
  let $expected :=
    if (exists($test/expected/@eval)
      and xs:boolean($test/expected/@eval))
    then xdmp:eval($expected, (), $options)
    else $expected
  (: should we construct a new value from the expected value? :)
  let $expected :=
    if (empty($test/expected/@construct)
      or not(xs:boolean($test/expected/@construct)))
    then $expected
    else xdmp:eval(concat($test/expected/@construct,
      "('", $expected, "')"))
  let $actual := xdmp:eval($test/xquery, (), $options)
  return test($expected, $actual, string($test/description))
}

define function test($tests as element(tests),
  $sections as xs:string*)
as xdt:anyAtomicType*
{
  for $t in $tests/test
    [ empty($sections) or cts:contains(text { $sections }, @section) ]
  return test($t)
}

xdmp:set-response-content-type("text/html; charset=utf-8"),
<html>
  <head>
    <title>lib-parser: unit tests</title>
  </head>
  <body>
    <h1>lib-parser: unit tests</h1>
    <p>If any of the following tests return "false",
    please contact the module author(s).
    </p>

<div class="test-results">
    <h3>debug</h3>
    <div>Debug is false by default: { $p:DEBUG eq false() }</div>
    <div>debug-on: 1... { p:debug-on(), $p:DEBUG }</div>
    <div>debug: 1... { p:debug("testing debug (on)"), "check ErrorLog.txt" }</div>
    <div>debug-off: 1... { p:debug-off(), $p:DEBUG eq false() }</div>
    <div>debug: 1... { p:debug("testing debug (off)"), "check ErrorLog.txt" }</div>

    <h3>terms-from-cts-query()</h3>
    {
      for $t at $x in <tests>
            <test>
              <description>Simple query</description>
              <raw>cts:word-query('foo')</raw>
              <value>foo</value>
            </test>
            <test>
              <description>Simple field-word query</description>
              <raw>cts:field-word-query('foo', 'bar')</raw>
              <value>bar</value>
            </test><test>
              <description>Complex query</description>
              <raw>
                  cts:and-query((cts:word-query('foo'),
                    cts:or-query(('bar', 'baz')),
                    cts:element-query(xs:QName('title'), 'buz')))
              </raw>
              <value>foo bar baz buz</value>
            </test>
          </tests>/test
      let $res := p:terms-from-cts-query(xdmp:eval($t/raw/text()))
      return element div {
        "terms-from-cts-query:", concat(string($x), "..."),
        test($res, tokenize($t/value, '\s+'), xdmp:quote($t/raw/text())) }
    }

    <h3>serialize-cts-query()</h3>
    {
      let $extra :=
        if (starts-with(xdmp:version(), '3.2-'))
        then <cts:option>lang=en</cts:option>
        else ()
      for $r at $x in test(
      <tests>
      {
        for $t in <tests>
            <test>
              <description>Simple query</description>
              <xquery>cts:word-query('foo')</xquery>
              <expected>
                <cts:query>
                  <cts:word-query weight="1">foo{$extra}</cts:word-query>
                </cts:query>
              </expected>
            </test>
            <test>
              <description>Simple element query</description>
              <xquery>
              cts:element-query(xs:QName('bar'), cts:word-query('foo'))
              </xquery>
              <expected>
                <cts:query>
                  <cts:element-query>
                    <cts:QName>bar</cts:QName>
                    <cts:word-query weight="1">foo{$extra}</cts:word-query>
                  </cts:element-query>
                </cts:query>
              </expected>
            </test>
          	<test>
              <description>Simple field-word query</description>
              <xquery>
              cts:field-word-query('bar', 'foo')
              </xquery>
              <expected>
                <cts:query>
                  <cts:field-word-query weight="1">
                    <cts:string-item>bar</cts:string-item>foo{$extra}</cts:field-word-query>
                </cts:query>
              </expected>
            </test>
            <test>
              <description>Simple element query, with namespace</description>
              <xquery>
              declare namespace t="test"
              cts:element-query(xs:QName('t:bar'), cts:word-query('foo'))
              </xquery>
              <expected>
                <cts:query>
                  <cts:element-query>
                    <cts:QName namespace-uri="test">bar</cts:QName>
                    <cts:word-query weight="1">foo{$extra}</cts:word-query>
                  </cts:element-query>
                </cts:query>
              </expected>
            </test>
            <test>
              <description>Near query</description>
              <xquery>cts:near-query(('bar', 'foo'))</xquery>
              <expected>
                <cts:query>
                  <cts:near-query distance="100" weight="1">
                    <cts:word-query weight="1">bar{$extra}</cts:word-query>
                    <cts:word-query weight="1">foo{$extra}</cts:word-query>
                  </cts:near-query>
                </cts:query>
              </expected>
            </test>
            <test>
              <description>Near query with distance</description>
              <xquery>cts:near-query(('bar', 'foo'), 5)</xquery>
              <expected>
                <cts:query>
                  <cts:near-query distance="5" weight="1">
                    <cts:word-query weight="1">bar{$extra}</cts:word-query>
                    <cts:word-query weight="1">foo{$extra}</cts:word-query>
                  </cts:near-query>
                </cts:query>
              </expected>
            </test>
            <test>
              <description>Element-attribute value query</description>
              <xquery>cts:element-attribute-value-query(
                xs:QName('foo'), xs:QName('bar'), 'baz')</xquery>
              <expected>
                <cts:query>
                  <cts:element-attribute-value-query weight="1">
                    <cts:element-QName>foo</cts:element-QName>
                    <cts:attribute-QName>bar</cts:attribute-QName>baz{$extra}
                  </cts:element-attribute-value-query>
                </cts:query>
              </expected>
            </test>
            <test>
              <description>Element-attribute word query</description>
              <xquery>cts:element-attribute-word-query(
                xs:QName('foo'), xs:QName('bar'), 'baz')</xquery>
              <expected>
                <cts:query>
                  <cts:element-attribute-word-query weight="1">
                    <cts:element-QName>foo</cts:element-QName>
                    <cts:attribute-QName>bar</cts:attribute-QName>baz{$extra}
                  </cts:element-attribute-word-query>
                </cts:query>
              </expected>
            </test>
          </tests>/test
      return element test {
        $t/node()[node-name(.) ne xs:QName('xquery')],
        element xquery {
          $IMPORT-MODULE,
          'p:serialize-cts-query(', xdmp:eval($t/xquery), ')'
        }
      }
      }
      </tests>, () )
      return element div {
        "serialize-cts-query:", concat(string($x), "..."), $r }
    }

    <h3>deserialize-query()</h3>
    {
        (: deserialize test, with unquote and whitespace :)
        let $tests :=
            <tests>
            {
              for $t in (
                <test>
                    <description>Field-word query</description>
                    <xquery><cts:field-word-query><cts:string-item>bar</cts:string-item>foo</cts:field-word-query></xquery>
                    <expected>{ cts:field-word-query('bar', 'foo') }</expected>
                </test>,
                <test>
                    <description>Word query</description>
                    <xquery><cts:word-query>foo</cts:word-query></xquery>
                    <expected>{ cts:word-query('foo') }</expected>
                </test>,
                <test>
                    <description>Word query with lang</description>
                    <xquery><cts:word-query>foo<cts:option>lang=en</cts:option></cts:word-query></xquery>
                    <expected>{ cts:word-query('foo') }</expected>
                </test>,
                <test>
                    <description>Query with whitespace</description>
                    <xquery><cts:query>foo</cts:query></xquery>
                    <expected>{ cts:word-query('foo') }</expected>
                </test>,
                <test mode="strict">
                    <description>Query with whitespace, strict mode</description>
                    <xquery><cts:query>
                        <cts:word-query>foo</cts:word-query>
                    </cts:query></xquery>
                    <expected>{ cts:word-query('foo') }</expected>
                </test>,
                <test mode="strict">
                    <description>Query with whitespace, strict mode</description>
                    <xquery><cts:query>foo</cts:query></xquery>
                    <expected error="1"><err:code>{$p:ERR-INVALID-QXML}</err:code></expected>
                </test>,
                <test>
                    <description>Passing search options with search element</description>
                    <xquery options="('case-insensitive','punctuation-sensitive','diacritic-insensitive')"><cts:query>
                        foo
                    </cts:query></xquery>
                    <expected>{ cts:word-query('foo', ("case-insensitive","punctuation-sensitive","diacritic-insensitive"), 1) }</expected>
                </test>,
                <test mode="strict">
                    <description>Passing search options with search element</description>
                    <xquery options="('case-insensitive','punctuation-sensitive','diacritic-insensitive')"><cts:query>
                        <cts:word-query>foo</cts:word-query>
                    </cts:query></xquery>
                    <expected>{ cts:word-query('foo', ("case-insensitive","punctuation-sensitive","diacritic-insensitive"), 1) }</expected>
                </test>,
                <test>
                  <description>Query with weighted terms</description>
                  <xquery>
                    <cts:query>
                      <cts:and-query>
                        <cts:word-query weight="1.7">foo</cts:word-query>
                        <cts:word-query weight="2.3">bar</cts:word-query>
                      </cts:and-query>
                    </cts:query>
                  </xquery>
                  <expected>{
                    cts:and-query((
                      cts:word-query("foo", (), 1.7),
                      cts:word-query("bar", (), 2.3) ))
                  }</expected>
                </test>
                )
                let $try :=
                    exists($t/expected/@error) and xs:boolean($t/expected/@error)
                return element test {
                    $t/node()[node-name(.) ne xs:QName('xquery')],
                    element xquery {
                        $IMPORT-MODULE,
                        if ($try) then 'try {' else (),
                        'p:deserialize-query(',
                        xdmp:quote($t/xquery/node()),
                        ',',
                        if ($t/@mode = 'strict') then 'true()' else 'false()',
                        ',',
                        if (fn:string($t/xquery/@options))
                        then fn:string($t/xquery/@options) else '()',
                        ')',
                        if ($try) then '} catch ($ex) { $ex/err:code }' else ()
                    }
                }
            }
            </tests>
        for $test at $x in $tests/test
        let $results := test($test)
        return element div {
            "deserialize-query:", concat(string($x), "..."), $results }
    }

    <h3>get-cts-query()</h3>
    {
      for $t at $x in
      <tests>
        <test>
          <description>Garbage input</description>
          <raw></raw>
          <value>()</value>
        </test>
        <test>
          <description>Garbage input</description>
          <raw>   </raw>
          <value>()</value>
        </test>
        <test>
          <description>Garbage input</description>
          <raw>(foo bar</raw>
          <value>cts:and-query((cts:word-query('foo'), cts:word-query('bar')))</value>
        </test>
        <test>
          <description>Garbage input</description>
          <raw>foo (bar</raw>
          <value>cts:and-query((cts:word-query('foo'), cts:word-query('bar')))</value>
        </test>
        <test>
          <description>Garbage input</description>
          <raw>foo) (bar</raw>
          <value>cts:and-query((cts:word-query('foo'), cts:word-query('bar')))</value>
        </test>
        <test>
          <description>Garbage input</description>
          <raw>foo) bar</raw>
          <value>cts:and-query((cts:word-query('foo'), cts:word-query('bar')))</value>
        </test>
        <test>
          <description>Simple search</description>
          <raw>foo</raw>
          <value>cts:word-query('foo')</value>
        </test>
        <test>
          <description>Simple search with wildcards</description>
          <raw>foo?bar*</raw>
          <value>cts:word-query('foo?bar*')</value>
        </test>
        <test>
          <description>Multiple-word search</description>
          <raw>foo bar</raw>
          <value>cts:and-query((cts:word-query('foo'), cts:word-query('bar')))</value>
        </test>
        <test>
          <description>Multiple-word search</description>
          <raw>foo bar</raw>
          <value>cts:and-query((cts:word-query('foo'), cts:word-query('bar')))</value>
        </test>
        <test>
          <description>Hyphen-term search</description>
          <raw>foo-bar</raw>
          <value>cts:word-query('foo-bar')</value>
        </test>
        <test>
          <description>Syntax for or-terms search</description>
          <raw>foo OR bar</raw>
          <value>cts:or-query((cts:word-query('foo'), cts:word-query('bar')))</value>
        </test>
        <test>
          <description>Alternative syntax for or-terms search</description>
          <raw>foo | bar</raw>
          <value>cts:or-query((cts:word-query('foo'), cts:word-query('bar')))</value>
        </test>
        <test>
          <description>Syntax for ignored and-terms search</description>
          <raw>foo bar AND baz</raw>
          <value>cts:and-query((cts:word-query('foo'), cts:word-query('bar'), cts:word-query('baz')))</value>
        </test>
        <test>
          <description>Proximity search</description>
          <raw>foo NEAR bar</raw>
          <value>cts:near-query((cts:word-query('foo'), cts:word-query('bar')))</value>
        </test>
        <test>
          <description>Proximity search with distance</description>
          <raw>foo NEAR/5 bar</raw>
          <value>cts:near-query((cts:word-query('foo'), cts:word-query('bar')), 5)</value>
        </test>
        <test>
          <description>Not-term search (NOT)</description>
          <raw>foo NOT bar</raw>
          <value>cts:and-query(('foo', cts:not-query(cts:word-query('bar'))))</value>
        </test>
        <test>
          <description>Not-term search (dash)</description>
          <raw>foo -bar</raw>
          <value>cts:and-query(('foo', cts:not-query(cts:word-query('bar'))))</value>
        </test>
         <test>
          <description>Not-phrase search (NOT)</description>
          <raw>NOT "foo bar"</raw>
          <value>cts:not-query(cts:word-query('foo bar'))</value>
        </test>
         <test>
          <description>Not-phrase search (dash)</description>
          <raw>-"foo bar"</raw>
          <value>cts:not-query(cts:word-query('foo bar'))</value>
        </test>
        <test>
          <description>Not-group search (NOT)</description>
          <raw>NOT (foo bar)</raw>
          <value>cts:not-query( cts:and-query((cts:word-query('foo'), cts:word-query('bar'))) )</value>
        </test>
        <test>
          <description>Not-group search (dash)</description>
          <raw>-(foo bar)</raw>
          <value>cts:not-query( cts:and-query((cts:word-query('foo'), cts:word-query('bar'))) )</value>
        </test>
         <test>
          <description>Not-group and phrase search (NOT)</description>
          <raw>NOT ("foo bar")</raw>
          <value>cts:not-query(cts:word-query('foo bar'))</value>
        </test>
         <test>
          <description>Not-group and phrase search (dash)</description>
          <raw>-("foo bar")</raw>
          <value>cts:not-query(cts:word-query('foo bar'))</value>
        </test>
         <test>
          <description>Not-group and phrase search (NOT)</description>
          <raw>NOT (moo "foo bar")</raw>
          <value>cts:not-query(cts:and-query((cts:word-query('moo'), cts:word-query('foo bar'))))</value>
        </test>
         <test>
          <description>Not-group and phrase search (dash)</description>
          <raw>-(moo "foo bar")</raw>
          <value>cts:not-query(cts:and-query((cts:word-query('moo'), cts:word-query('foo bar'))))</value>
        </test>
         <test>
          <description>Not-group and phrase search (NOT)</description>
          <raw>NOT ("foo bar" moo)</raw>
          <value>cts:not-query(cts:and-query((cts:word-query('foo bar'), cts:word-query('moo'))))</value>
        </test>
         <test>
          <description>Not-group and phrase search (dash)</description>
          <raw>-("foo bar" moo)</raw>
          <value>cts:not-query(cts:and-query((cts:word-query('foo bar'),cts:word-query('moo'))))</value>
        </test>
        <test>
          <description>Tricky not-term search</description>
          <raw>"foo OR bar" -baz</raw>
          <value>
          cts:and-query(('foo OR bar', cts:not-query(cts:word-query('baz'))))</value>
        </test>
        <test>
          <description>Grouping of search terms</description>
          <raw>(foo | bar) baz</raw>
          <value>cts:and-query((cts:or-query((
            cts:word-query('foo'), cts:word-query('bar'))), 'baz'))</value>
        </test>
        <test>
          <description>Tricky grouping of search terms</description>
          <raw>foo | (bar baz)</raw>
          <value>cts:or-query((cts:word-query('foo'),
            cts:and-query((cts:word-query('bar'), cts:word-query('baz')))))</value>
        </test>
        <test>
          <description>Larger grouping of search terms</description>
          <raw>(foo | bar) baz buz biz</raw>
          <value>cts:and-query((cts:or-query(('foo', 'bar')), 'baz', 'buz', 'biz'))</value>
        </test>
        <test>
          <description>Quoted phrase search</description>
          <raw>foo OR "foo bar"</raw>
          <value>cts:or-query(('foo', 'foo bar'))</value>
        </test>
        <test>
          <description>Punctuation-sensitive search</description>
          <raw>foo&apos;s bar</raw>
          <value>cts:and-query((cts:word-query("foo's"), cts:word-query("bar")))</value>
        </test>
        <test>
          <description>Reversed quoted phrase search</description>
          <raw>"foo bar" OR foo</raw>
          <value>cts:or-query(('foo bar', 'foo'))</value>
        </test>
        <test>
          <description>Unterminated quoted phrase search</description>
          <raw>&quot;foo bar</raw>
          <value>cts:word-query('foo bar')</value>
        </test>
        <test>
          <description>Field-based search</description>
          <raw>foo title:bar</raw>
          <value>cts:and-query(('foo',
            cts:element-word-query(xs:QName('title'), 'bar')))</value>
        </test>
        <test>
          <description>Field-based search</description>
          <raw>title:</raw>
          <value>cts:element-query(xs:QName('title'), cts:and-query(()))</value>
        </test>
        <test>
          <description>Field-based search with quoted term</description>
          <!-- note the extra quotes -->
          <raw>'title:"foo bar"'</raw>
          <value>cts:element-word-query(xs:QName('title'), 'foo bar')</value>
        </test>
        <test>
          <description>Field-based value search</description>
          <raw>heading=foo title=bar</raw>
          <value>cts:and-query((
            cts:element-value-query((xs:QName('h1'), xs:QName('h2'),
              xs:QName('h3'), xs:QName('h4'), xs:QName('h5')), 'foo'),
            cts:element-value-query(xs:QName('title'), 'bar')))</value>
        </test>
        <test>
          <description>Field-based search with booleans</description>
          <raw>foo (title:bar OR title:baz)</raw>
          <value>cts:and-query(('foo',
            cts:or-query((
              cts:element-word-query(xs:QName('title'), 'bar'),
              cts:element-word-query(xs:QName('title'), 'baz') )) ))</value>
        </test>
        <test>
          <description>Field-based search with punctuation</description>
          <raw>foo title:http://bar.com/baz?foo=bar&amp;baz</raw>
          <value>cts:and-query(('foo',
            cts:element-word-query(xs:QName('title'),
              'http://bar.com/baz?foo=bar&amp;baz') ))</value>
        </test>
        <test>
          <description>Field-based search, with custom mapping table (3.2 Fields)</description>
          <raw>foo weighted:bar</raw>
          <p:search-field-map>
            <p:mapping code="weighted" field="weighted"/>
          </p:search-field-map>
          <value>cts:and-query(('foo', cts:field-word-query('weighted', ('bar'))))</value>
        </test>
        <test>
          <description>Field-based search (3.2 Fields)</description>
          <raw>foo weighted:bar</raw>
          <value>cts:and-query(('foo',
            cts:field-word-query('weighted', 'bar')))</value>
        </test>
        <test>
          <description>Field-based search (3.2 Fields)</description>
          <raw>weighted:</raw>
          <value>cts:field-word-query('weighted', ())</value>
        </test>
        <test>
          <description>Field-based search with quoted term (3.2 Fields)</description>
          <!-- note the extra quotes -->
          <raw>'weighted:"foo bar"'</raw>
          <value>cts:field-word-query('weighted', 'foo bar')</value>
        </test>
        <test>
          <description>Field-based search with booleans (3.2 Fields)</description>
          <raw>foo (weighted:bar OR weighted:baz)</raw>
          <value>cts:and-query(('foo',
            cts:or-query((
              cts:field-word-query('weighted', 'bar'),
              cts:field-word-query('weighted', 'baz') )) ))</value>
        </test>
        <test>
          <description>Field-based search with punctuation (3.2 Fields)</description>
          <raw>foo weighted:http://bar.com/baz?foo=bar&amp;baz</raw>
          <value>cts:and-query(('foo',
            cts:field-word-query('weighted',
              'http://bar.com/baz?foo=bar&amp;baz') ))</value>
        </test>
        <test>
          <description>Field-based search, with custom mapping table (3.2 Fields)</description>
          <raw>foo weighted:bar</raw>
          <p:search-field-map>
            <p:mapping code="weighted" field="weighted bar"/>
          </p:search-field-map>
          <value>cts:and-query(('foo', cts:field-word-query(
            ('weighted','bar'), 'bar') ))</value>
        </test>
        <test>
          <description>Field-based search, with custom mapping table and options (3.2 Fields)
          </description>
          <raw>foo title=bar</raw>
          <p:search-field-map>
            <p:mapping code="title" field="weighted foo"
             options="case-insensitive unwildcarded"/>
          </p:search-field-map>
          <value>cts:and-query(('foo', cts:field-word-query(
            ('weighted', 'foo'), 'bar',
             ('case-insensitive', 'unwildcarded') ) ))</value>
        </test>
        <test>
          <description>Field-based search, with custom mapping table</description>
          <raw>foo title:bar</raw>
          <p:search-field-map>
            <p:mapping code="title" qname="title TITLE"/>
          </p:search-field-map>
          <value>cts:and-query(('foo', cts:element-word-query(
            (xs:QName('title'), xs:QName('TITLE')), 'bar') ))</value>
        </test>
        <test>
          <description>Field-based search, with custom mapping table and options
          </description>
          <raw>foo title=bar</raw>
          <p:search-field-map>
            <p:mapping code="title" qname="title TITLE"
             options="case-insensitive unwildcarded"/>
          </p:search-field-map>
          <value>cts:and-query(('foo', cts:element-value-query(
            (xs:QName('title'), xs:QName('TITLE')), 'bar',
             ('case-insensitive', 'unwildcarded') ) ))</value>
        </test>
        <test>
          <description>
            Field-based search, with custom mapping table and namespaces
          </description>
          <raw>foo title:bar</raw>
          <p:search-field-map xmlns:t="test">
            <p:mapping code="title"><t:title/><t:TITLE/></p:mapping>
          </p:search-field-map>
          <value>cts:and-query((cts:word-query("foo", (), 1), cts:element-word-query((expanded-QName("test", "title"), expanded-QName("test", "TITLE")), "bar", (), 1)), ())</value>
        </test>
        <test>
          <description>
            Passing search options with search
          </description>
          <raw options="case-insensitive|punctuation-sensitive|diacritic-insensitive">foo</raw>
          <value>cts:word-query("foo", ("case-insensitive","punctuation-sensitive","diacritic-insensitive"), 1)</value>
        </test>
      </tests>/test
      return element div {
        "get-cts-query:", concat(string($x), "...", $t/description),
        test(
            p:get-cts-query($t/raw, $t/p:search-field-map, if (fn:string($t/raw/@options)) then fn:tokenize(fn:string($t/raw/@options), "\|") else ()),
            xdmp:eval($t/value),
            $t/raw
            )
        }
    }
</div>

    <div>
    All tests complete.
    <pre>{ xdmp:quote(xdmp:query-meters()) }</pre>
    </div>
</body>
</html>