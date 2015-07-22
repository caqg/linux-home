jQuery.fn.pulldown = function() {
  var t = this;

  var togglePulldown = function(t) {
    // position

    var topPos = $(t).children(".label").position().top + $(t).children(".label").outerHeight();
    $(t).children("ul").css({
      position: "absolute",
      top: topPos,
      zIndex: 1001
    });

    var center = $(window).width() / 2,
        leftPos = $(t).children(".label").position().left,
        menuWidth = $(t).children('ul').width();
    if (leftPos < center) {
      $(t).children("ul")
        .css('left', leftPos);
    } else if (($(window).width() - leftPos) > menuWidth) {
      $(t).children("ul")
        .css('left', leftPos);
    } else {
      $(t).children("ul")
        .css('left', leftPos + $(t).children(".label").outerWidth() - menuWidth);
    }

    $(t).children("ul")
      .css('height', 'auto')
      .toggle();

    if ($(t).children("ul").css("display") !== "none") {
      // Adjust Width
      if($(t).width() > $(t).children("ul").width()) {
        $(t).children("ul").width($(t).width() + 30);
      }

      // Adjust height
      topPos = $(t).children(".label").offset().top + $(t).children(".label").outerHeight();
      if ((topPos + $(t).children("ul").outerHeight()) > $(window).height()) {
        $(t).children("ul").height($(window).height() - topPos - 10);
      }

      $(t).children(".label").addClass("selected");
            
      // background event
      var bg = document.createElement("div");
      $(bg)
        .addClass("pulldown-bg-layer")
        .css("position","absolute")
        .css("top", 0)
        .css("left", 0)
        .css("width", $(window).width())
        .css("height", $(window).height())
        .css("background","white")
        .css("opacity", 0.0)
        .css("z-index",1000);
      $(bg).click(function() {
        togglePulldown(t);
      });
      $(t).before(bg)      
    } else {
      $(t).children(".label").removeClass("selected");
      $(".pulldown-bg-layer").remove();
    }
  };

  $(this).each(function(i,item) {
	  $(item).children(".label").click(function() {
	    if ($(item).children("ul").children("li").size() > 0) {
  	    togglePulldown(item);
  	  }
	  });
	
	  $(item).children("ul").children("li").click(function() {
      //console.log("CLICK:" + $(this).text());
      if ($(this).attr("data-ignore-click") !== "yes") {
  	    togglePulldown(item);
      }
	  });

	  $(item).children(".label").show();
	  $(item).children("ul").hide();
	
  });
};