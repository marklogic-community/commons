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
 :     http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :
 : Ported to XQuery version 1.0, November 2008.
 : 
 : @author Ryan Grimm (grimm@xqdev.com)
 : @version 0.2
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
	let $matches := sum(
		for $gone in $modifierNodes
		return if($node is $gone) then 1 else 0
	)
	return
		if($mode = "delete")
		then
			if($matches > 0)
			then $newNode
			else mem:_processNode($node, $modifierNodes, $newNode, $mode)
		else if($mode = "insert-child")
		then
			if($matches > 0)
			then element { QName(namespace-uri($node), local-name($node)) } { (
					$node/@*, $node/node(), $newNode
				) }
			else mem:_processNode($node, $modifierNodes, $newNode, $mode)
		else if($mode = "insert-after")
		then
			if($matches > 0)
			then ($node, $newNode)
			else mem:_processNode($node, $modifierNodes, $newNode, $mode)
		else if($mode = "insert-before")
		then
			if($matches > 0)
			then ($newNode, $node)
			else mem:_processNode($node, $modifierNodes, $newNode, $mode)
		else ()
};

(:
	Constructs a node if need be and processes all of its children
:)
declare function mem:_processNode(
	$node as node(),
	$modifierNodes as node()*,
	$newNode as node()*,
	$mode as xs:string
) as node()
{
	if($node instance of element(*))
	then element { QName(namespace-uri($node), local-name($node)) } {
		for $child in ($node/@*, $node/node())
        return mem:_process($child, $modifierNodes, $newNode, $mode)

	}
	else $node
};

