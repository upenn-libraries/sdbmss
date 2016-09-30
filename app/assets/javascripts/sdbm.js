
/**
 * Common library for the SDBM namespace.
 *
 * NOTE: Things here should be fairly generic and depend only on
 * site-wide libraries specified in applications.js.
 */

/* Hints for eslint: */
/* global $ */

var SDBM = SDBM || {};

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
                }
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

});