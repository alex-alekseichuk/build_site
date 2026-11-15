// Copyright 2006-2007 javascript-array.com, imporved by Eugene Mirotin 2008

var timeout	= 500;
var closetimer	= 0;
var ddmenuitem	= 0;

// open hidden layer
function showSubmenu(menu1)
{	
	// cancel close timer
	cancelMenuClosing();

	// close old layer
	if(ddmenuitem) ddmenuitem.style.visibility = 'hidden';

	// get new layer and show it
	ddmenuitem = getElementsByClass('bsMenuContainer2', menu1, 'div')[0];
	ddmenuitem.style.visibility = 'visible';

}
// close showed layer
function hideMenu()
{
	if (ddmenuitem && closetimer) 
	{
		ddmenuitem.style.visibility = 'hidden';
		cancelMenuClosing();
	}
}

// go close timer
function setMenuClosing()
{
	closetimer = window.setTimeout(hideMenu, timeout);
}

// cancel close timer
function cancelMenuClosing()
{
	if(closetimer)
	{
		window.clearTimeout(closetimer);
		closetimer = null;
	}
}

// close layer when click-out
document.onclick = hideMenu; 
