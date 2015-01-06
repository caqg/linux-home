jQuery.fn.tooltip = function() {
  var showTooltip = function(target) {
    var _showTooltip = function() {
      var tri = document.createElement("div")
          tip = document.createElement("div");
      $(tri)
        .addClass("tooltip-triangle");
      $(tip)
        .addClass("tooltip-text")
        .text($(target).attr("data-tooltip"));

      if ($(target).attr("data-tooltip-alignleft") === 'true') {
        $(tri).addClass("tooltip-triangle-gray");
        $(tip).addClass("tooltip-text-gray");
      }


      $(target).parent()
        .after(tip)
        .after(tri);

      var top_tri = $(target).position().top + $(target).outerHeight() + 3;
      var top_tip = top_tri + 8;
      if ($(target).attr("data-tooltip-alignleft") === 'true') {
        var left_tri = $(target).position().left + 30;
        var left_tip = $(target).position().left + 20;
      } else {
        var left_tri = $(target).position().left + $(target).outerWidth() / 2 - ($(tri).width() / 2);
        var left_tip = $(target).position().left + $(target).outerWidth() / 2 - ($(tip).width() / 2);
      }

      $(tri)
        .css("top",top_tri + "px")
        .css("left",left_tri + "px");
      $(tip)
        .css("top",top_tip + "px")
        .css("left",left_tip + "px");
    };

    return _showTooltip;
  };
  var hideTooltip = function() {
    $(".tooltip-triangle").remove();
    $(".tooltip-text").remove();
  };

  var in_status = [];
  $(this).each(function(i,item) {
    var this_index = i;
    in_status[this_index] = "out";
    $(item).hover(
      function() {
        //console.log("in:" + this_index);
        // in
        in_status[this_index] = "in";
        setTimeout(function() {
          //console.log("timeout:" + this_index + " " + in_status[this_index]);
          if (in_status[this_index] === "in") {
            showTooltip(item)();
          }
        }, 300)
      },
      function() {
        //console.log("out:" + this_index);
        // out
        in_status[this_index] = "out";
        /*
        setTimeout(function() {
          console.log("timeout:" + this_index + " " + in_status[this_index]);
          if (in_status[this_index] === "out") {
		        hideTooltip();
          }
        }, 200)
        */
        hideTooltip();
      }
    );

    $(item).click(function() { hideTooltip(); });
  });
};