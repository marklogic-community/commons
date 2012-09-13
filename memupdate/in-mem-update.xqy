xquery version "1.0";
(:~
 :
 : Copyright 2007 Ryan Grimm
 :
 : A module to update in memory nodes.  These function are intended to
 : mirror the built in update function (eg: xdmp:node-insert-child).
 : One difference between these functions and the built in update functions
 : is that the new node can actually be a sequence of nodes.  It is
 : recommended to use this feature as much as possible for performance
 : reasons.  Another difference is that these functions return the
 : modified XML back to you.
 :
 : Note: Functions that start with an underscore are private functions.
 :
 :
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 :	  http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :
 : Ported to XQuery version 1.0, November 2008.  Patches added May 2011.
 : 
 : @author Ryan Grimm (grimm@xqdev.com)
 : @version 0.3
 :
 :)

module namespace mem = "http://xqdev.com/in-mem-update";
declare default function namespace "http://www.w3.org/2005/xpath-functions";

(:
	Inserts the given nodes as children of the given node
:)
declare function mem:node-insert-child(
	$parentNode as element(),
	$newNode as node()*
) as node()
{
	mem:_process(root($parentNode), $parentNode, $newNode, "insert-child")
};

(:
	Inserts the new nodes before the given node
:)
declare function mem:node-insert-before(
	$sibling as node(),
	$newNode as node()*
) as node()
{
	mem:_process(root($sibling), $sibling, $newNode, "insert-before")
};

(:
	Inserts the new nodes after the given node
:)
declare function mem:node-insert-after(
	$sibling as node(),
	$newNode as node()*
) as node()
{
	mem:_process(root($sibling), $sibling, $newNode, "insert-after")
};

(:
	Replaces the given nodes with the new node
:)
declare function mem:node-replace(
	$goneNodes as node()*,
	$newNode as node()
) as node()
{
	mem:_process(root($goneNodes[1]), $goneNodes, $newNode, "delete")
};

(:
	Deletes the given nodes
:)
declare function mem:node-delete(
	$goneNodes as node()*
) as node()?
{
	mem:_process(root($goneNodes[1]), $goneNodes, (), "delete")
};

(: Private functions :)

(:
	Processes an element.  Elements that match one of the modifier nodes are
	handeled depending on the mode.  Don't feel bad if you don't quite
	understand this code.
:)
declare function mem:_process(
	$node as node(),
	$modifierNodes as node()*,
	$newNode as node()*,
	$mode as xs:string
) as node()*
{
	if (some $gone in $modifierNodes satisfies $node is $gone)
	then
		 if ($mode eq "delete")
		 then
			  $newNode
		 else if ($mode eq "insert-child")
		 then
			  element{ QName(namespace-uri($node), local-name($node)) }
			  {
					typeswitch ($newNode)
					  case attribute() return
						 ( $node/@*, $newNode, $node/node() )
					  default return
						 ( $node/@*, $node/node(), $newNode )
			  }
		 else if ($mode eq "insert-after")
		 then
			  ($node, $newNode)
		 else if ($mode eq "insert-before")
		 then
			  ($newNode, $node)
		 else ()
	else
		 typeswitch ($node)
			case element() return
			  element { QName(namespace-uri($node), local-name($node)) }
			  {
					for $child in ($node/@*, $node/node())
					return
					  mem:_process($child, $modifierNodes, $newNode, $mode)
			  }
			case document-node() return
			  document
			  {
					for $child in $node/node()
					return
						 mem:_process($child, $modifierNodes, $newNode, $mode)
			  }
			default return
			  $node
};
