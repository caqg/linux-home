function closePopup(){if(SAFARI)for(var b=safari.extension.toolbarItems,a=0;a<b.length;a++){if("clipper"==b[a].identifier&&b[a].popover){b[a].popover.hide();break}}else window.close()};
