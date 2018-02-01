
/**
 * Common library for the SDBM namespace.
 *
 * NOTE: Things here should be fairly generic and depend only on
 * site-wide libraries specified in applications.js.
 */

/* Hints for eslint: */
/* global $ */

var SDBM = SDBM || {};

var base_ten = Math.log(10);
if (Math.log10 === undefined) Math.log10 = function (n) {
  return Math.log(n) / base_ten;
};

function addNotification (message, type, permanent) {
  var notification = $('<div><a class="close" data-dismiss="alert" aria-label="close">&times;</a>' + message + "</div>");
  notification.addClass('alert').addClass('alert-' + type).addClass('alert-absolute');
  
  notification.hide();
  $('.alerts-absolute').append(notification);
  notification.fadeIn();
  
  if (!permanent) {
    setTimeout(function () {
      notification.fadeOut('slow', function () {
        notification.remove();
      });
    }, 10000);
  } // fade out after ten seconds;
}

function load_activity (url, day) {
  $("#loader").show();
  loading = true;
  //console.log('href');
  $.get(url, {day: day}, function(result){      
      //var loaded = JSON.parse(result);
      //console.log(loaded);
      var loaded = result;
      //console.log('mmm!');
      if (loaded.activities && loaded.activities[0]) {

          var date = loaded.activities[0].date;
          var date_header = $("<h4 class='text-center'><a class='float-right' data-toggle='collapse' data-target='.activity-" + date + "'>" + date + " <span class='caret'></span></a></h4>");
          var date_body = $("<div class='collapse collapse in'></div>");
          $("#activity-content").append(date_header);
          $("#activity-content").append(date_body);

          for (var user in loaded.activities[0].activities) {
              var user_header = $("<p class='text-center' data-toggle='collapse' data-target='#activity-" + date + "-" + user + "'</p>");
              var user_body = $("<div class='list-group collapse collapse in activity-" + date + "' id='activity-" + date + "-" + user + "'></div>");

              date_body.append(user_header);
              date_body.append(user_body);

              var details = loaded.activities[0].activities;
              var count = 0;

              for (var title in details[user]) {
                  count++;
                  var cl = 'list-group-item-';
                  if (title.indexOf('edited') === 0) cl += 'info';
                  else if (title.indexOf('added') === 0) cl += 'success';
                  else if (title.indexOf('deleted') === 0) cl += 'danger';
                  else cl = '';

                  user_body.append($("<div class='list-group-item " + cl + "'><h4 class='list-group-item-heading'>" + title + "</h4> <p class='list-group-item-text'>" + details[user][title] + "</p></div>"));                    
                  //console.log(title, details[user][title]);
              }
              user_header.html('<a href="/profiles/' + user + '" target="_blank">' + user + '</a> modified ' + count + ' record' + (count > 1 ? 's' : '') + ' <span class="caret"></span>');
          }
          //var users = .activities;

      } else {
        $("#activity-content").append("<p class='text-muted text-center'>There is no more recent activity to display</p>");
      }

      //bindRemoteAjaxCallback();
      //console.log("DAY",day);
      if (day < 6) {
          //day++;
          load_activity(url, ++day);
      } else {
          loading = false;
          $("#loader").hide();        
      }

  });

}


function exportCSV(url) {
  dataConfirmModal.confirm({
    title: 'Download CSV?',
    text: 'Are you sure you would like to download your current search as a CSV file?  It may take some time.',
    commit: 'Yes',
    cancel: 'Cancel',
    zIindex: 10099,
    onConfirm: function() {
      $.get(url).done(function (e) {
          if (e.error) {
              if (e.error == "at limit") {
                  addNotification("You have reached your export limit.  Download or delete some of your exports <a href='/downloads/'>here</a>.", "danger");
              }
              return;
          }

          var myDownloadComplete = false;
          $('#user-nav a').css({color: 'green'});
          addNotification("CSV Export is being prepared...", "info");
          var download = JSON.parse(e);
          var url = "/downloads/" + download.id;
          var count = 0;
          var interval = setInterval( function () {
              $.ajax({url: url, data: {ping: true}}).done( function (r) {
                  //window.location = url;
                  if (r != "in progress" && !myDownloadComplete) {
                      addNotification(download.filename + " is ready - <a href='" + url + "'>download file</a>", "success", true);
                      $('#user-nav a').css({color: ''});
                      $('#downloads-count').text(download.count);
                      window.clearInterval(interval);
                      myDownloadComplete = true;
                  } else {
                      count += 1;
                  }

                  if (count > 1000) { window.clearInterval(interval); }
              }).error( function (r) {
                  console.log('error', r);
                  window.clearInterval(interval);
              });
          }, 1000);
      }).error( function (e) {
          console.log('error', e);
      });
    },
    onCancel:  function() { }
  });
}

$(document).ready(bindRemoteAjaxCallback);


// 12-06-17 fix me: make consistent between ratings, bookmarks, watch, etc.
function bindRemoteAjaxCallback (){
  //selector = selector === undefined ? 
  $('a[data-remote]').on('ajax:success', function (event, xhr, status, result) {
      //console.log('result.responseJSON', result.responseJSON);
      var errors = [];
      if (result.responseJSON.button) {
        $(this).replaceWith(result.responseJSON.button);
      }
      else {
        for (var key in result.responseJSON.results) {
          if (result.responseJSON.results[key].button_html) {
            $("." + key).replaceWith(result.responseJSON.results[key].button_html);          
          } else if (result.responseJSON.results[key].error) {
            errors.push(result.responseJSON.results[key].error);
          }
        }
        if (errors.length > 0) {
          console.log("ERRORS: ", errors);        
        }
      }
      $('a[data-remote]').unbind('ajax:success');
      bindRemoteAjaxCallback();
  });

  $('a[data-remote]').on('ajax:error', function (event, xhr, status, error) {
    console.log("remote link (bookmark) error", event, xhr, status, error, xhr.responseText);
  });
}

(function () {

    "use strict";

    /**
     * Show a modal popup using Bootstrap's js modal code.
     */
    SDBM.showModal = function(selectorStr, options) {
        var defaults = {
            allowDismiss: false,
            showFooter: true,
            body: "",
            title: ""
        };
        options = $.extend({}, defaults, options);
        $(selectorStr).find(".modal-title").html(options.title);
        $(selectorStr).find(".modal-body").html(options.body);
        if(!options.showFooter) {
            $(selectorStr).find(".modal-footer").hide();
        }
        if(!options.allowDismiss) {
            $(selectorStr).modal({ keyboard: false, backdrop: 'static' });
            $(selectorStr).find(".close").hide();
        }
        $(selectorStr).modal('show');
    };

    /**
     * a version of showModal tailored for showing an error message
     */
    SDBM.showErrorModal = function(selectorStr, msg) {
        SDBM.showModal(selectorStr, {
            allowDismiss: true,
            showFooter: true,
            title: "An error occurred",
            body: msg
        });
    };

    /**
     * registers the qtip tooltip plugin on specified elements, using
     * the given template filename
     */
    SDBM.registerTooltip = function(selector, template) {
        var s = $(selector).qtip({
            style: {
                classes: 'sdbmss-tooltip'
            },
            content: {
                text: 'Loading...',
                ajax: {
                    // force reload
                    cache: false,
                    url: '/static/tooltips/' + template + '.html',
                    type: 'GET'
                },
                title: '<div class="text-right"><a href="/pages/' + template + '/edit"><span class="glyphicon glyphicon-edit"></span> Edit Tooltip</a></div>'
            },
            position: {
                my: 'center',
                at: 'center',
                target: $(window)
            },
            show: {
                event: 'click'
            },
            hide: {
                event: 'unfocus'
            }
        });
    };

    SDBM.hideNavBar = function() {
        $("#search-navbar").hide();
    };

    SDBM.setPageFullWidth = function() {
        //SDBM.hideNavBar();
        // make this page take up full width of browser window
        $("#main-container").removeClass("container").addClass("container-fluid");
    };


    // Takes a date string d in format 'YYYYMMDD' representing a fuzzy
    // date (where 0's are used as placeholders for no month or date), and
    // returns it in one of these formats: YYYY-MM-DD, YYYY-MM, or YYYY
    SDBM.dateDashes = function(date) {
        var y, m, d, dashed;
        if(date) {
            if(date.length === 8) {
                y = date.substring(0, 4);
                m = date.substring(4, 6);
                d = date.substring(6, 8);
                dashed = y;
                if(m && m !== '00') {
                    dashed += "-" + m;
                }
                if(d && d !== '00') {
                    dashed += "-" + d;
                }
                return dashed;
            }
        }
        return date;
    };

    SDBM.disableFormSubmissionOnEnter = function(selector) {
    // disallow user from submitting the form by pressing Enter
        $(selector).on("keyup keypress", function(e) {
            var code = e.keyCode || e.which;
            if (code === 13) {
                e.preventDefault();
                return false;
            }
        });
    };

    var entityMap = {
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        '"': '&quot;',
        "'": '&#39;',
        "/": '&#x2F;'
    };

    SDBM.escapeHtml = function(string) {
        return String(string).replace(/[&<>"'\/]/g, function (s) {
            return entityMap[s];
        });
    };

    /* 'errors' is a data structure found in a Rails model
     * object's model.errors.messages attribute when validation fails
     * for it. This fn transforms that data structure into an array
     * of strings.
     */
    SDBM.parseRailsErrors = function(errors) {
        var strings = [];
        if(errors) {
            for(var key in errors) {
                if(key === 'base') {
                    strings.push(errors[key]);
                } else {
                    strings.push(key + " " + errors[key]);
                }
            }
        }
        return strings;
    };

}());

$(document).ready( function (e) {

    // disable site-wide autocomplete
    $('input').attr('autocomplete','off');
    //$('[data-toggle="popover"]').popover(); 

    // remember control panel display from last set (localstorage memory)
    if (localStorage.getItem('sdbm_hide_panel') == "true") {
        $('#control-panel').removeClass('in');
        $('.main-content').addClass('in');
    } else {

    }

    // set control panel display (localstorage) memory
    $('#collapse-control').click( function (e) {
        if ($('#control-panel').hasClass('in')) {
            localStorage.setItem('sdbm_hide_panel', true);
        } else {
            localStorage.setItem('sdbm_hide_panel', false);
        }
    });

});