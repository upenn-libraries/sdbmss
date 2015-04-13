
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

SDBM.hideNavBar = function() {
    $("#search-navbar").hide();
};

SDBM.setPageFullWidth = function() {
    SDBM.hideNavBar();
    // make this page take up full width of browser window
    $("#main-container").removeClass("container").addClass("container-fluid");
};


// Takes a date string d in format 'YYYYMMDD' representing a fuzzy
// date (where 0's are used as placeholders for no month or date), and
// returns it in one of these formats: YYYY-MM-DD, YYYY-MM, or YYYY
SDBM.dateDashes = function(date) {
    var y, m, d, dashed;
    if(date) {
        if(date.length == 8) {
            y = date.substring(0, 4);
            m = date.substring(4, 6);
            d = date.substring(6, 8);
            dashed = y;
            if(m && m != '00') {
                dashed += "-" + m;
            }
            if(d && d != '00') {
                dashed += "-" + d;
            }
            return dashed;
        }
    }
    return date;
};
