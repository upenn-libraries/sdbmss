function saveCurrentSearch () {
  var t = $("#save_current_search");
  t.addClass("disabled");
  $.post('/saved_searches/save/' + t.attr('search'), {_method: 'put'}).done( function (result) {
    // trigger response on success
    alert("Your search has been saved succesfully");
    t.removeClass("disabled");
  }).error( function (result) {
    // trigger response on failure
    // FIX ME: blank search doesn't save properly!
    alert("There was an error saving your search");
    console.log("ERROR: ", result);
    t.removeClass("disabled");
  });
}