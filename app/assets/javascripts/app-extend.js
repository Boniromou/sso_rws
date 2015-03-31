//$.ajax({ cache: false });

//$('div#content').on('ajax:error', function(xhr, status, error) {
//  $(this).html(xhr.responseText);
//});

var troll = new Troll(function() {
  $('body').addClass("smart-style-3");
});

$(document).ajaxError(function (e, xhr, settings) {
  if (xhr.status == 401) {
    location.reload();
  }
});

$('nav').on('ajax:beforeSend', function(xhr, settings) {
  var container = $('div#content');
  container.removeData().html("");
  container.html('<h1 class="ajax-loading-animation"><i class="fa fa-cog fa-spin"></i> Loading...</h1>');
});

$(document).on('ajax:complete', function(xhr, status) {
  //console.log("hereeeeeeeeee");
  //console.log(xhr);
  //console.log(status);
});

//.not('form#search_form')
/*
$('div#content > form#search_form').on('ajax:beforeSend', function(xhr, settings) {
  var container = $('div#content');
  $(#audit_logs_result)
  container.removeData().html("");
  container.html('<h1 class="ajax-loading-animation"><i class="fa fa-cog fa-spin"></i> Loading...</h1>');
});
*/
window.paceOptions = {
  elements: false,
  restartOnRequestAfter: true
}

// Date Range Picker
$("#from").datepicker({
    defaultDate: "+1w",
    changeMonth: true,
    numberOfMonths: 1,
    prevText: '<i class="fa fa-chevron-left"></i>',
    nextText: '<i class="fa fa-chevron-right"></i>',
    onClose: function (selectedDate) {
        $("#to").datepicker("option", "minDate", selectedDate);
    }

});
$("#to").datepicker({
    defaultDate: "+1w",
    changeMonth: true,
    numberOfMonths: 1,
    prevText: '<i class="fa fa-chevron-left"></i>',
    nextText: '<i class="fa fa-chevron-right"></i>',
    onClose: function (selectedDate) {
        $("#from").datepicker("option", "maxDate", selectedDate);
    }
});

// flash message
$(document).ready(function() {
  if ($('div#message_content').length > 0) {
    var flash_type = $('div#message_content').parent()
    if (flash_type.hasClass("alert alert-success")) {
      $.smallBox({
        title : "Success",
        content : $('div#message_content').text(),
        color : "#659265",
        iconSmall : "fa fa-check fa-2x fadeInRight animated",
      });
    } else if (flash_type.hasClass("alert-warning")) {
      $.smallBox({
        title : "Fail",
        content : $('div#message_content').text(),
        color : "#C46A69",
        iconSmall : "fa fa-times fa-2x fadeInRight animated",
      });
    }
  }
});