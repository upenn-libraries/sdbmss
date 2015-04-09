
/**
 * Common library for the SDBM namespace.
 *
 * NOTE: Things here should be fairly generic and depend only on
 * site-wide libraries specified in applications.js.
 */

var SDBM = SDBM || {};

/**
 * Show a modal popup using Bootstrap's js modal code.
 */
SDBM.showModal = function(selector_str, options) {
    var defaults = {
        allowDismiss: false,
        showFooter: true,
        body: "",
        title: ""
    };
    options = $.extend({}, defaults, options);
    $(selector_str).find(".modal-title").html(options.title);
    $(selector_str).find(".modal-body").html(options.body);
    if(!options.showFooter) {
        $(selector_str).find(".modal-footer").hide();
    }
    if(!options.allowDismiss) {
        $(selector_str).modal({ keyboard: false, backdrop: 'static' });
        $(selector_str).find(".close").hide();
    }
    $(selector_str).modal('show');
};

/**
 * a version of showModal tailored for showing an error message 
 */
SDBM.showErrorModal = function(selector_str, msg) {
    SDBM.showModal(selector_str, {
        allowDismiss: true,
        showFooter: true,
        title: "An error occurred",
        body: msg
    });
};
