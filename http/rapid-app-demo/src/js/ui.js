var hideClass = "hidden";

/* Given a group of elements, will show 1 and hide the others */
function toggleElementGroup(primeElement, eArray) {
	for (var i = 0; i < eArray.length; i++)
		if (primeElement == eArray[i])
			Element.show( eArray[i] )
		else
			Element.hide( eArray[i] )
}

/* Given a group of elements, will add a class to 1 and remove
the class from the others */
function toggleElementGroupStyle(primeElement, eArray, style) {
	for (var i = 0; i < eArray.length; i++)
		if (primeElement == eArray[i])
			Element.addClassName( eArray[i], style )
		else
			Element.removeClassName( eArray[i], style )
}

/* Will swap a '+' and '-' depending on the value of the current element */
function swapPlusMinus(tgtElement) {
	if (tgtElement.innerHTML == '+') {
		tgtElement.innerHTML = '&#x2013;';
	} else {
		tgtElement.innerHTML = '+';
	}
}

/* Checks for a style on an element, and alternatively adds/removes it */
function toggleStyle(elementId, toggleClass) {
	if(!$(elementId).hasClassName(toggleClass)){
		$(elementId).addClassName(toggleClass);
	}else{
		$(elementId).removeClassName(toggleClass);
	}
}

/* Similar to prototype's Element.toggle() except using classes instead of style. */
function show(elementId){showToggle(elementId);}
function showToggle(elementId){
	toggleStyle(elementId, hideClass);
}

/* Similar to prototype's Element.show/hide except using classes instead of style. */
function showChoose(elementId, showValue){
	if ($(elementId)) {
		if (showValue) {
			if($(elementId).hasClassName(hideClass))
				$(elementId).removeClassName(hideClass);
		} else {
			if(!$(elementId).hasClassName(hideClass)) {
				$(elementId).addClassName(hideClass);
			}
		}
	}
}

// Loader function that once loading content, will not load it again.
function toggleLoadedContent(result_div,url,request_opts,alwaysGet){
	if(!$(result_div).hasClassName(hideClass) && !alwaysGet){
		$(result_div).addClassName(hideClass);
	}else{
		if($(result_div).innerHTML != "|" && !alwaysGet){
			$(result_div).removeClassName(hideClass);
		}else{
			$(result_div).removeClassName(hideClass);
			$(result_div).innerHTML = "<img class='loading' src='/images/common/spinner.gif'/>";
			new Ajax.Updater(result_div,url,request_opts);
		}
	}
}
