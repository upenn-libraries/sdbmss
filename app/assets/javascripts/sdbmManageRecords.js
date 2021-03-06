
/*
 * Provides a SDBM.ManageRecords class for displaying a listing of
 * records in a datatable, including functionality for:
 *
 * - marking records as 'reviewed'
 * - changing URL when table results change via AJAX
 *
 * This is designed to maximize reuse: individual pages can subclass
 * to override some behaviors, like how columns are rendered.
 */

var SDBM = SDBM || {};
var load_session = false;

(function () {

    "use strict";

    // This constructor should be called on the document.ready event
    // for a page.
    SDBM.ManageRecords = function(options) {

        var defaults = {
            resourceName: null,
            resourceNameSingular: null,
            resourceNamePlural: null,
            showOnlyRecordsCreatedByUser: false,
            searchNameField: "name"
        };

        this.options = $.extend({}, defaults, options);

        var manageRecords = this;
        
//        SDBM.hideNavBar();

        window.onpopstate = function(event) {
            // load the data from URL into page
            //manageRecords.setFormStateFromURL();
            manageRecords.dataTable.reload();
        };

        //manageRecords.setFormStateFromURL();
        
        this.dataTable = manageRecords.createTable(".sdbm-table");

        $(".sdbm-table").on("click", ".delete-link", function(event) {
            dataConfirmModal.confirm({
                title: 'Confirm',
                text: 'Are you sure you want to delete this record?',
                commit: 'Yes',
                cancel: 'Cancel',
                zIindex: 10099,
                onConfirm: function() { 
                    $.ajax({
                        url: $(event.target).attr("href"),
                        method: 'DELETE',
                        error: function(xhr) {
                            var error = $.parseJSON(xhr.responseText).error;
                            SDBM.showModal("#modal", {title: "ERROR: Could not delete record", body: error });
                            //alert("An error occurred deleting this record: " + error);
                        },
                        success: function(data, textStatus, jqXHR) {
                            manageRecords.dataTable.reload();                    
                        }
                    });
                },
                onCancel:  function() { }
            });
            return false;
        });
        
        $('form.search-form').submit(manageRecords.createFormSubmitHandler());

        $('#export-csv').click(function() {
            manageRecords.exportCSV();
            return false;
        });

        $(document).on('click', "#select-all", function(event) {
            if (!$("#select-all").prop("all-selected")) {
                $("#select-all").prop("all-selected", true);
                $("input[name='review']").prop("checked", true);
            } else {
                $("#select-all").prop("all-selected", false);
                $("input[name='review']").prop("checked", false);
            }
        });

        $(document).on('click', "#deselect-all", function(event) {
            $("input[name='review']").prop("checked", false);
            return false;
        });

        $(document).on('click', '#add-to-group', function (event) {
            var ids = [];
            var checkbox_name = manageRecords.options.resourceName == "entries" ? "approve" : "review";
            $("input[name='" + checkbox_name + "']:checked").each(function (idx, element) {
                ids.push($(element).val());
            });
            var group_id = $('#group-select').val();
            var editable = $('#editable').prop('checked') || false;
            
            if (ids.length > 0) {
                $("#spinner").show();
                $.ajax({
                    url: '/' + manageRecords.options.resourceName + '/add_to_group.json',
                    type: 'POST',
                    data: { ids: ids, group_id: group_id, editable: editable },
                    success: function(data, textStatus, jqXHR) {
                        if (data.response) {
                            SDBM.showModal("#modal", {title: "Records Added To Group", body: data.response });
                        }
                        manageRecords.dataTable.reload();
                        $("#group_modal").modal("toggle");
                    },
                    error: function() {
                        SDBM.showErrorModal("#modal", "An unspecified error occurred adding record(s) to a user group");
                    },
                    complete: function() {
                        $("#spinner").hide();
                    }
                });
            }
        });

        $(document).on('click', '#remove-from-group', function (event) {
            var ids = [];
            var checkbox_name = manageRecords.options.resourceName == "entries" ? "approve" : "review";
            $("input[name='" + checkbox_name + "']:checked").each(function (idx, element) {
                ids.push($(element).val());
            });
            var group_id = $('#group-select').val();

            if (ids.length > 0) {
                $("#spinner").show();
                $.ajax({
                    url: '/' + manageRecords.options.resourceName + '/remove_from_group.json',
                    type: 'POST',
                    data: { ids: ids, group_id: group_id },
                    success: function(data, textStatus, jqXHR) {
                        if (data.response) {
                            SDBM.showModal("#modal", {title: "Records Removed From Group", body: data.response });
                        }
                        manageRecords.dataTable.reload();
                        $("#group_modal").modal("toggle");
                    },
                    error: function() {
                        SDBM.showErrorModal("#modal", "An error occurred removing record(s) from a user group");
                    },
                    complete: function() {
                        $("#spinner").hide();
                    }
                });
            }
        });

        $(document).on('click', "#mark-as-reviewed", function(event) {
            var ids = [];
            $("input[name='review']:checked").each(function (idx, element) {
                ids.push($(element).val());
            });
            
            if(ids.length > 0) {
                $("#spinner").show();
                $.ajax({
                    url: '/' + manageRecords.options.resourceName + '/mark_as_reviewed.json',
                    type: 'POST',
                    data: { ids: ids },
                    success: function(data, textStatus, jqXHR) {
                        manageRecords.dataTable.reload();
                    },
                    error: function() {
                        SDBM.showErrorModal("#modal", "An error occurred marking records as reviewed");
                    },
                    complete: function() {
                        $("#spinner").hide();
                    }
                });
            }

            return false;
        });

        if(this.getButtonTextForAddNewRecord()) {
            $(".add-new-record").find('.name').text(this.getButtonTextForAddNewRecord());
        } else {
            $(".add-new-record").hide();
        }
    };

    /** Creates the table object instance */
    SDBM.ManageRecords.prototype.createTable = function(selector) {
        var manageRecords = this;

        var sdbmTable = new SDBM.Table(selector, {
            ajax: function (sdbmTable, dt_params, callback, settings) {

                if (load_session) {
                    var params = JSON.parse($('#last_search').attr('data'));
                    manageRecords.setFormStateFromParams(params);
                    load_session = false;
                } else {                    
                    var params = manageRecords.createSearchParams(dt_params);
                }

                if (params.reviewed) {
                    params.unreviewed_only = 1;
                }
                $("#spinner").show();

                manageRecords.searchAjax(params, dt_params, callback);
            },
            heightBuffer: 280,
            columns: manageRecords.getColumns(),
            order: manageRecords.getDefaultSort(),
            fixedColumns: manageRecords.options.fixedColumns, 
        });

        $("#search_results").on('draw.dt', function () {
            sdbmTable.dataTable.rows().nodes().each(function (row, idx, api) {
                var data = sdbmTable.dataTable.row(row).data();
                // because sometimes it's a string, and sometimes its a boolean.  it just is.
                if(!data[sdbmTable.getColumnIndex("Approved")] || data[sdbmTable.getColumnIndex("Approved")] == 'false') {
                    $(row).addClass('warning unapproved');
                }
            });
        });

        return sdbmTable;
    };

    SDBM.ManageRecords.prototype.searchAjax = function(params, dt_params, callback) {
        var manageRecords = this;
        $.ajax({
            url: '/' + manageRecords.options.resourceName + '/search.json',
            data: params,
            success: function(data, textStatus, jqXHR) {
                if(!data.error) {
                    $(".dataTables_scrollBody").scrollTop(0);
                    var rows = [];
                    data.results.forEach(function(item) {
                        rows.push(manageRecords.searchResultToTableRow(item));
                    });
                    callback({
                        draw: dt_params.draw,
                        data: rows,
                        recordsTotal: data.total,
                        recordsFiltered: data.total
                    });
//                    renewBookmarks();

/*                    if (manageRecords.getUnreviewedOnly() === 1)
                        $('.unreviewed_only').show();//.css({"display": "table-cell"});
                    else
                        $('.unreviewed_only').hide();//.css({"display": "none"});*/
                } else {
                    SDBM.showModal("#modal", {title: "ERROR: Could not fetch search results", body: data.error });
                    //alert("An error occurred fetching search results: " + data.error);
                }
            },
            error: function() {
                SDBM.showErrorModal("#modal", "An error occurred fetching search results");
            },
            complete: function() {
                $("#spinner").hide();
            }
        });
    };
    
    // returns an object to pass to jquery $.ajax() call
    SDBM.ManageRecords.prototype.createSearchParams = function (dt_params) {
        var columns = this.getColumns();
        var orderStr = "";
        dt_params.order.forEach(function(item) {
            orderStr += columns[item.column].dbSortField + " " + item.dir;
        });

        var search_query = {
            reviewed: this.getUnreviewedOnly(),
            created_by_user: this.options.showOnlyRecordsCreatedByUser,
            offset: dt_params.start,
            limit: dt_params.length,
            order: orderStr,
            op: this.getOp()
        };

        for (var i = 0; i < $(".search-block").length; i++) { 
            var search_row = $(".search-block").eq(i);
            var term = search_row.find("input[name=search_value]").val();
            var field = search_row.find("select[name=search_field]").val();
            var option = search_row.find("select[name=search_option]").val();

            if ( search_query[field] ) {
                search_query[field].push(term);
            } else {
                search_query[field] = [term];
            }

            var option_string = field + "_option";
            if (search_query[option_string]) {
                search_query[option_string].push(option);
            } else {
                search_query[option_string] = [option];
            }
        }
        this.search_query = search_query;
        return search_query;
    };

    // returns a bookmarkable URL that contains current state of page
    // and search form

    SDBM.ManageRecords.prototype.persistFormStateToURL = function () {
        var manageRecords = this;
        return URI(manageRecords.getResourceIndexURL()).search({
            term: manageRecords.getSearchValue(),
            unreviewed_only: manageRecords.getUnreviewedOnly()
        });
    };

    SDBM.ManageRecords.prototype.setFormStateFromURL = function() {
        var manageRecords = this;
        var qs = new URI().query(true);
        var j = 0;
        for (var key in qs) {
            var key_string = key.replace(/\[|\]/g, '');
            qs[key] = Array.isArray(qs[key]) ? qs[key] : [qs[key]];
            for (var i = 0; i < qs[key].length; i++) {
                var item = qs[key][i];
                $('select[name=search_field]').eq(j).val(key_string);
                $('input[name=search_value]').eq(j).val(item);
                $('#addSearch').click();
                j += 1;
            }
        }
//        $("input[name='search_value']").first().val(qs.term);
        if(qs && (qs.unreviewed_only === '1' || qs.reviewed === '1')) {
            $("input[name='unreviewed_only']").prop('checked', true);
        }
        manageRecords.showOrHideMarkCheckedRecordsButton();
    };

    SDBM.ManageRecords.prototype.setFormStateFromParams = function (params) {
        var manageRecords = this;
        var qs = params;
        var j = 0;
        for (var key in qs) {
            if (Array.isArray(qs[key]) && key.indexOf('option') == -1) {                
                
                if (j != 0) $('#addSearch').click();
                var key_string = key;
                var option_string = key + "_option";
                for (var i = 0; i < qs[key].length; i++) {
                    var item = qs[key][i];
                    var option = qs[option_string][i];
                    $('select[name=search_field]').eq(j).val(key_string);
                    $('input[name=search_value]').eq(j).val(item);
                    $('select[name=search_option]').eq(j).val(option);
                    j += 1;
                }
            }
        }
//        $("input[name='search_value']").first().val(qs.term);
        if(qs && qs.unreviewed_only === '1') {
            $("input[name='unreviewed_only']").prop('checked', true);
        }
        manageRecords.showOrHideMarkCheckedRecordsButton();
    }
    
    // factory method that returns a function used for search form
    // submit handler
    SDBM.ManageRecords.prototype.createFormSubmitHandler = function () {
        var manageRecords = this;

        return function(e) {
            e.preventDefault();
//          var url = manageRecords.persistFormStateToURL();
//          history.pushState({ url: url }, '', url);
            manageRecords.reloadTable();
            
            manageRecords.showOrHideMarkCheckedRecordsButton();
            return false;
        };
    };

    SDBM.ManageRecords.prototype.reloadTable = function() {
        var manageRecords = this;
        manageRecords.dataTable.reload();
    };

    SDBM.ManageRecords.prototype.getDefaultSort = function () {
        return [[ 2, "desc" ]];
    };
    
    SDBM.ManageRecords.prototype.getResourceIndexURL = function () {
        return '/' + this.options.resourceName + '/';
    };
    
    SDBM.ManageRecords.prototype.getSearchURL = function (format) {
        var url =  '/' + this.options.resourceName + '/search';
        if(format) {
            url += "." + format;
        }
        return url;
    };

    SDBM.ManageRecords.prototype.getSearchValue = function() {
        return $("input[name='search_value']").val();
    };

    SDBM.ManageRecords.prototype.getSearchField = function() {
        return $("select[name='search_field']").val();
    };

    SDBM.ManageRecords.prototype.getSearchOption = function() {
        return $("select[name='search_option']").val();
    };
    
    SDBM.ManageRecords.prototype.getUnreviewedOnly = function() {
        if ($("input[name='unreviewed_only']").is(':checked')) {
            $('.hideIfReviewed').removeClass('disabled');
            return 1;
        } else {
            $('.hideIfReviewed').addClass('disabled');
            return 0;
        }
    };

    SDBM.ManageRecords.prototype.getOp = function () {
        if ($('#search_op')) {
            return $('#search_op').val();
        } else {
            return 'all';
        }
    }
    
    SDBM.ManageRecords.prototype.getColumns = function () {
        var manageRecords = this;

        return [
            {
                title: '<input type="checkbox" id="select-all" class="hideIfReviewed">',//'<a href="#" class="btn btn-default btn-blank btn-xs glyphicon glyphicon-unchecked hideIfReviewed" id="select-all"></a>',
                orderable: false,
                className: "text-center unreviewed_only",
                render: function (data, type, full, meta) {
                    //if(manageRecords.getUnreviewedOnly() === 1) {
                        /*return  '' + 
                                '<input class="table-checkbox" type="checkbox" name="review" value="' + full[manageRecords.dataTable.getColumnIndex("ID")] + '" id="checkbox_' + meta.row + '"/>' + 
                                '<label for="checkbox_' + meta.row + '">' + 
                                '<a class="btn btn-default btn-xs btn-blank glyphicon glyphicon-unchecked unchecked"></a>' + 
                                '<a class="btn btn-default btn-xs btn-blank glyphicon glyphicon-check checked"></a>' + 
                                '</label>' + '';*/
                        return '<input type="checkbox" name="review" value="' + full[manageRecords.dataTable.getColumnIndex("ID")] + '"/>';
                    //}
                    //return '';
                },
                width: "5%"
            },
            {
                title: 'Options',
                orderable: false,
                render: function (data, type, full, meta) {
                    var str = '<a class="btn btn-xs btn-success" href="/' + manageRecords.options.resourceName + '/' + data + '/edit/">Edit</a> '
                            + ' <a class="delete-link btn btn-xs btn-danger" href="/' + manageRecords.options.resourceName + '/' + data + '.json">Delete</a>';
                    return str;
                },
                width: "10%"
            },
            {
                title: 'ID',
                width: "8%",
                dbSortField: 'id',
                render: function (data, type, full, meta) {
                    var str = '<a href="/' + manageRecords.options.resourceName + '/' + data + '">' + data + '</a>';
                    return str;
                }
            },
            {
                title: 'Name',
                width: "45%",
                dbSortField: manageRecords.options.searchNameField
            },
            {
                title: 'Count',
                width: "10%",
                dbSortField: 'entries_count'
            },
            {
                title: 'Approved',
                width: "10%",
                dbSortField: 'reviewed'
            },
            {
                title: 'Problem',
                width: "10%",
                dbSortField: 'problem'
            },
            {
                title: 'Added By',
                width: "10%",
                dbSortField: 'created_by'
            },
            {
                title: 'Added On',
                width: "10%",
                dbSortField: 'created_at'
            },
            {
                title: 'Updated By',
                width: "10%",
                dbSortField: 'updated_by'
            },
            {
                title: 'Updated On',
                width: "10%",
                dbSortField: 'updated_at'
            }
        ];
    };

    // translates a search result object into an Array used to populate datatable
    SDBM.ManageRecords.prototype.searchResultToTableRow = function (result) {
        return [ null, result.id, result.id, result[this.options.searchNameField], result.entries_count || 0, result.reviewed, result.problem, result.created_by || "", result.created_at || "", result.updated_by || "", result.updated_at || "" ];
    };

    SDBM.ManageRecords.prototype.showOrHideMarkCheckedRecordsButton = function() {
        if(this.getUnreviewedOnly() === 1) {
            //$(".review-control").show();
        } else {
            //$(".review-control").hide();
        }
    };

    // should return null if button should not be displayed
    SDBM.ManageRecords.prototype.getButtonTextForAddNewRecord = function() {
        return "Add New " + this.options.resourceNameSingular.charAt(0).toUpperCase() + this.options.resourceNameSingular.slice(1);
    };
    
    // handler called when "export csv" link is clicked; this
    // implementation uses #search action on the Rails resource
    // controller
    
    SDBM.ManageRecords.prototype.getCSVSearchUrl = function () {
        var manageRecords = this;
        //var qs = new URI().query(true);
        var qs = manageRecords.search_query;

        // since this data is sent via URI, I have to reformat when there is a list so {name: ["x", "y"]} becomes {name[]: ["x", "y"]} 
        for (var field in qs) {
            if (Array.isArray(qs[field])) {
                if (field.indexOf('[]') == -1) {
                    qs[field + "[]"] = qs[field];
                    delete qs[field];
                }
            }
        }

        return URI(manageRecords.getSearchURL('csv')).search(qs);
    };

    SDBM.ManageRecords.prototype.exportCSV = function() {
        var t = this;
        var url = t.getCSVSearchUrl();
        exportCSV(url);
    };
    
}());
