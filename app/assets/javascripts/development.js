
/* JS to run in development only */

$(document).ready(function () {
    $("<a href='#' class='development'>DEVELOPMENT</a>").insertAfter(".navbar-brand");

    var dialog = $("#development-dialog").dialog({
        autoOpen: false,
        modal: true,
        height: 300,
        width: 500
    });
    
    $(document).on('click', '.development', function() {
        dialog.dialog("open");
    });
});
