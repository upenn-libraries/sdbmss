//= require blacklight/core
//= require blacklight/checkbox_submit

(function($) {
//change form submit toggle to checkbox
    Blacklight.do_bookmark_toggle_behavior = function() {
        $(Blacklight.do_bookmark_toggle_behavior.selector).submit( function (e) {
          e.preventDefault();
          var t = $(this);
          var url = t.attr('action');
          var data = {};
          t.find('input').each( function (i, input) {
            data[$(input).attr('name')] = $(input).val();
          });
          var submit = $.post(url, data);
          submit.done( function (results) {
            if (data._method == 'delete') {
              t.find('.submit').val('Bookmark').addClass('bookmark_add').removeClass('bookmark_remove');
              t.find('input[name=_method]').val('put');
            } else {
              t.find('.submit').val('Remove Bookmark').addClass('bookmark_remove').removeClass('bookmark_add');
              t.find('input[name=_method]').val('delete');
            }
            $.get('/bookmarks/reload', function () { console.log('hi'); }).done(
              function (results) {
                var results = $(results).find('#my_bookmarks').addClass('in');
                $('#my_bookmarks').replaceWith(results);
              }).error( function (results) {
                console.log('error reloading bookmarks', results);
              });
          });
          submit.fail( function (results) {
            console.log("bookmark_toggle (error)", results);
          })
        });
    };
    Blacklight.do_bookmark_toggle_behavior.selector = "form.bookmark_toggle"; 

    Blacklight.do_bookmark_all = function () {
      $('.bookmark_add').click();
    }

    Blacklight.do_clear_bookmarks = function () {
      $('.bookmark_remove').click();
    }

Blacklight.onLoad(function() {
  Blacklight.do_bookmark_toggle_behavior();  
});
  

})(jQuery);
