Abstract: Scaffolding is useful for making quick text edits and minor structural changes to existing xml files.

Warning: This script can make modifications to the contents of your MarkLogic database. USE AT YOUR OWN RISK. Do not make this file accessible in a production environment unless you really know what you're doing. There are still unresolved bugs, see below.

Notes:

    * Able to make text-node updates to any xml documents it has access to.
    * Able to duplicate (insert) sibling elements, and remove elements altogether. Careful when removing, if you remove the last node of it's kind, there's no way to bring it back.
    * Doesn't handle elements which contain both text-node AND element-node children. For example, an element containing markup-like content such as <message>xquery is <b>lots</b> of <i>fun</i></message> will be read as <message>xquery is lots of fun</message>.
    * The MarkLogic user executing this script must have permission to execute xdmp:eval.
    * This file is entirely self-contained, no dependancies. Just drop it anywhere in your project and go.
    * Apologies for the complete lack of commenting, this is still in the works.

Bugs: When saving a document containing attributes which are part of an element which has only text-node children (ex. <sign width="10" height="5">hello</sign>), those attributes vanish (ex. <sign>hello</sign>). Attributes which are part of an element which has only element-node children are saved successfully. If you grab the command from the log and execute it standalone (in CQ, for example), given the same document, the attributes are saved successfully. I still have no idea why this is happening, see line 41 and 43 of this file.

Motivation: Our website translations reside in xml files. I find it useful to view a translation with Scaffolding to make quick edits and additions to the output phrases, rather than editing a local file and re-loading it into MarkLogic for every change.

Contact: Please direct all comments/suggestions to eric.palmitesta@utoronto.ca, all feedback is welcome. I'd also love to know what you're using this utility for, and if you found it useful.

Eric Palmitesta
eric.palmitesta@utoronto.ca