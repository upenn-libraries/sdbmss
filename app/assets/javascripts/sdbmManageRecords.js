
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
        
        SDBM.hideNavBar();

        var setFormStateFromURL = function() {
            var qs = new URI().query(true);
            $("input[name='search_value']").val(qs.term);
            if(qs.unreviewed_only === '1') {
                $("input[name='unreviewed_only']").prop('checked', true);
            }
            manageRecords.showOrHideMarkCheckedRecordsButton();
        };

        window.onpopstate = function(event) {
            // load the data from URL into page
            setFormStateFromURL();
            manageRecords.dataTable.reload();
        };

        setFormStateFromURL();
        
        var columns = this.getColumns();
        
        this.dataTable = new SDBM.Table(".sdbm-table", {
            ajax: function (sdbmTable, dt_params, callback, settings) {

                var params = manageRecords.createSearchParams(dt_params);

                $("#spinner").show();
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
                        } else {
                            alert("An error occurred fetching search results: " + data.error);
                        }
                    },
                    error: function() {
                        // TODO: fill this out
                        alert("An error occurred fetching search results");
                    },
                    complete: function() {
                        $("#spinner").hide();
                    }
                });
            },
            columns: columns,
            order: manageRecords.getDefaultSort()
        });

        $(".sdbm-table").on("click", ".delete-link", function(event) {
            if(confirm("Are you sure you want to delete this record?")) {
                $.ajax({
                    url: $(event.target).attr("href"),
                    method: 'DELETE',
                    error: function(xhr) {
                        var error = $.parseJSON(xhr.responseText).error;
                        alert("An error occurred deleting this record: " + error);
                    },
                    success: function(data, textStatus, jqXHR) {
                        manageRecords.dataTable.reload();                    
                    }
                });
            }
            return false;
        });
        
        $('form.search-form').submit(function() {
            var url = URI(manageRecords.getResourceIndexURL()).search({
                term: manageRecords.getSearchValue(),
                unreviewed_only: manageRecords.getUnreviewedOnly()
            });

            history.pushState({ url: url }, '', url);

            manageRecords.dataTable.reload();

            manageRecords.showOrHideMarkCheckedRecordsButton();

            return false;
        });

        $('#export-csv').click(function() {
            var qs = new URI().query(true);

            var url = URI(manageRecords.getSearchURL('csv')).search({
                term: manageRecords.getSearchValue(),
                unreviewed_only: manageRecords.getUnreviewedOnly()
            });

            window.location = url;
            return false;
        });

        $(document).on('click', "#select-all", function(event) {
            $("input[name='review']").prop("checked", true);
            return false;
        });

        $(document).on('click', "#deselect-all", function(event) {
            $("input[name='review']").prop("checked", false);
            return false;
        });

        $(document).on('click', "#mark-as-reviewed", function(event) {
            var ids = [];
            $("input[name='review']:checked").each(function (idx, element) {
                ids.push($(element).val());
            });
            
            if(ids.length > 0) {
                // TODO: spinner
                $.ajax({
                    url: '/' + manageRecords.options.resourceName + '/mark_as_reviewed.json',
                    type: 'POST',
                    data: { ids: ids },
                    success: function(data, textStatus, jqXHR) {
                        manageRecords.dataTable.reload();
                    },
                    error: function() {
                        // TODO: fill this out
                        alert("An error occurred marking records as reviewed");
                    }
                });
            }

            return false;
        });

        if(this.getButtonTextForAddNewRecord()) {
            $(".add-new-record").text(this.getButtonTextForAddNewRecord());
        } else {
            $(".add-new-record").hide();
        }
    };

    // returns an object to pass to jquery $.ajax() call
    SDBM.ManageRecords.prototype.createSearchParams = function (dt_params) {
        var columns = this.getColumns();
        var orderStr = "";
        dt_params.order.forEach(function(item) {
            orderStr += columns[item.column].dbSortField + " " + item.dir;
        });

        return {
            term: this.getSearchValue(),
            unreviewed_only: this.getUnreviewedOnly(),
            created_by_user: this.options.showOnlyRecordsCreatedByUser,
            offset: dt_params.start,
            limit: dt_params.length,
            order: orderStr
        };
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
    
    SDBM.ManageRecords.prototype.getUnreviewedOnly = function() {
        return $("input[name='unreviewed_only']").is(':checked') ? 1 : 0;
    };
    
    SDBM.ManageRecords.prototype.getColumns = function () {
        var manageRecords = this;

        return [
            {
                title: '',
                orderable: false,
                render: function (data, type, full, meta) {
                    if(manageRecords.getUnreviewedOnly() === 1) {
                        return '<input type="checkbox" name="review" value="' + full[manageRecords.dataTable.getColumnIndex("ID")] + '"/>';
                    }
                    return '';
                },
                width: "5%"
            },
            {
                title: 'Options',
                orderable: false,
                render: function (data, type, full, meta) {
                    var str = '<a href="/' + manageRecords.options.resourceName + '/' + data + '/edit/">Edit</a> '
                            + '&middot; <a class="delete-link" href="/' + manageRecords.options.resourceName + '/' + data + '.json">Delete</a>';
                    return str;
                },
                width: "10%"
            },
            {
                title: 'ID',
                width: "8%",
                dbSortField: 'id'
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
                title: 'Reviewed',
                width: "10%",
                dbSortField: 'reviewed'
            },
            {
                title: 'Created By',
                width: "10%",
                dbSortField: 'created_by_id'
            }
        ];
    };

    // translates a search result object into an Array used to populate datatable
    SDBM.ManageRecords.prototype.searchResultToTableRow = function (result) {
        return [ null, result.id, result.id, result[this.options.searchNameField], result.entries_count || 0, result.reviewed, result.created_by || "" ];
    };

    SDBM.ManageRecords.prototype.showOrHideMarkCheckedRecordsButton = function() {
        if(this.getUnreviewedOnly() === 1) {
            $(".review-control").show();
        } else {
            $(".review-control").hide();
        }
    };

    // should return null if button should not be displayed
    SDBM.ManageRecords.prototype.getButtonTextForAddNewRecord = function() {
        return "Add New " + this.options.resourceNameSingular.charAt(0).toUpperCase() + this.options.resourceNameSingular.slice(1);
    };
    
}());
