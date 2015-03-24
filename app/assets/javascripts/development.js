
/* JS to run in development only */

$(document).ready(function () {
    $("<a href='#' class='development'>&#9733;DEVELOPMENT&#9733;</a>").insertAfter(".navbar-brand");

    var dialog = $("#development-dialog").dialog({
        autoOpen: false,
        modal: true,
        height: 400,
        width: 500
    });
    
    $(document).on('click', '.development', function() {
        dialog.dialog("open");
        return false;
    });
});
