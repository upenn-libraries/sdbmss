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
}
 
function reloadBookmarks () {
  $.get('/bookmarks/reload', function () {}).done(setupBookmarks).error( function (results) {
    console.log('error reloading bookmarks', results);
  });  
}

reloadBookmarks();

});