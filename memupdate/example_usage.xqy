xquery version "1.0";
(:~
 :
 : Copyright 2007 Ryan Grimm
 :
 : An example on how to use the in memory update module.
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

import module namespace mem = "http://xqdev.com/in-mem-update" at "/lib/in-mem-update.xqy";

<results>{
	let $foo :=
		<foo a="1">
			<?pi Here is a processing instruction ?>
			<bar a="2">
				<baz a="3"/>
			</bar>
		</foo>
	return (
		mem:node-delete($foo/processing-instruction()),
		mem:node-insert-child($foo/bar/baz, <new_node/>),
		mem:node-insert-before($foo/bar, <new_node/>),
		mem:node-insert-after($foo/bar, (<new_node_1/>, <new_node_2/>)),
		mem:node-replace($foo/bar, <new_node_1/>)
	)
}</results>
