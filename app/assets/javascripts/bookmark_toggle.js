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
  $('.new-merge').click( function (e) {
    window.location = $(location).attr('href').split('?')[0] + "?target_id=" + $(this).attr("target");
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