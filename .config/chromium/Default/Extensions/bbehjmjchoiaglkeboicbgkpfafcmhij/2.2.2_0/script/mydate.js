var mydate = {};

mydate._getDateDiff = function(src, dst) {
  var offset_min = (src.getTime() - dst.getTime()) / (1000*60);
  var offset_day = offset_min / (24*60);

  offset = {};
  offset.year = Math.floor(offset_day / 365);
  offset.month = Math.floor(offset_day / 30);
  offset.day = Math.floor(offset_day);
  offset.hour = Math.floor(offset_min / 60);
  offset.min = Math.floor(offset_min);

  return offset;
};

mydate._getDateObj = function(target) {
  var MONTH_STR = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];

  var date = {};
  date.year = target.getFullYear();
  date.month = (target.getMonth() + 1);
  date.month_en = MONTH_STR[parseInt(target.getMonth())];
  date.day = target.getDate();
  date.hour = target.getHours();
  date.min = target.getMinutes();
  date.date = target;
  
  return date;
};

mydate.getWhen = function(d) {
  var local_date = d;
  var today = new Date();
  
  var offset = mydate._getDateDiff(today, local_date);
  var when = "";
  // for debug
  //console.log(offset.day + "days" + offset.hour + "hours" + offset.min + "minutes");
  if (offset.day > 30) {
    var local_date_obj = mydate._getDateObj(local_date);
    when = local_date_obj.month_en + " " + local_date_obj.day + ", " + local_date_obj.year;
  } else if (offset.day > 1) {
    when = offset.day + " days ago";
  } else if (offset.day > 0) {
    when = "1 day ago";
  } else if (offset.hour > 1) {
    when = offset.hour + " hours ago";
  } else if (offset.hour > 0) {
    when = "1 hour ago";
  } else if (offset.min > 1) {
    when = offset.min + " minutes ago";
  } else if (offset.min > 0) {
    when = "1 minute ago";
  } else {
    when = "now";
  }

  return when;
};