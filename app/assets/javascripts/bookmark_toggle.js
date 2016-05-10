//= require blacklight/core
//= require blacklight/checkbox_submit
window.addEventListener("DOMContentLoaded", function (e) {

function setupBookmarks (results) {
  if (results) {
    $('#my_bookmarks').replaceWith(results);
  }
  $('.control-bookmark').click( function (e) {
    $.ajax({url: $(this)[0].href, method: $(this)[0].dataset.method}).done(reloadBookmarks);
    return false;
  });
  $('.bookmark-link').each( function (bl) {
    if ($('.check_bookmarks[href="' + $(this).attr('in_bookmarks') + '"]').length > 0) {
      $(this).css("color", "gold");
    } else {
      $(this).css("color", "");
    }
  });
  $('.new-merge').click( function (e) {
    window.location = $(location).attr('href').split('?')[0] + "?target_id=" + $(this).attr("target");
  });
  $('.tag-bookmark').click( function (e) {
    $(this).closest('.list-group-item').find('.add-bookmark-tag').toggle();
    return false;
  });
  $('.add-bookmark-tag-confirm').click( function (e) {
    var tag = $(this).prev('input').val(), url = $(this).attr('href');
    console.log(tag, url);
    $.get(url, {tag: tag}).done( function (result) {
      console.log(result);
    }).error ( function (result) {
      console.log("Add tag error: ", result);
    });
    return false;
  });
  $('.remove-bookmark-tag-confirm').click( function (e) {
    var url = $(this).attr('href');
    $.get(url).done( function (result) {
      console.log(result);
    }).error( function (result) {
      console.log("Remove tag error: ", result);
    });
    return false;
  });
}
 
function reloadBookmarks () {
  var can_merge = $(location).attr('href').match(/\/([a-zA-Z]+)\/\d+\/merge/);
  if (can_merge) can_merge = can_merge[1];
  var can_link = $(location).attr('href').match(/\/linkingtool\//) != null;
  $.get('/bookmarks/reload', {can_merge: can_merge, can_link: can_link}, function () {}).done(setupBookmarks).error( function (results) {
    console.log('error reloading bookmarks', results);
  });  
}

reloadBookmarks();

});