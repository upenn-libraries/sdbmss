
/*
 * This is a wrapper class around a dataTable that configures the
 * widget with reasonable defaults for most tables on the website, and
 * allows customization. It loads rows using server-side processing.
 *
 * Arguments:
 *
 * selector = jquery selector string specifying the table element
 *
 * options = object containing the following keys:
 *
 *  ajax: callback used to fetch results and populate table.
 *  This has the signature: function (sdbmTable, dt_params,
 *  callback, settings)
 *
 *  order: this gets passed to datatable for its 'order' option,
 *  except that we also translate column name strings to integer
 *  indexes.
 *
 *  columns: array of column definitions to pass to DataTable. This
 *  can include sdbmss extension options.
 *
 *  fixedColumns: if set to an integer, enables the FixedColumns
 *  extension and sets the number of left-most fixed columns. defaults
 *  to off.
 *
 *  dom: layout configuration string to pass to DataTable.
 *
 *  prependColumns: array of objects describing column options, which
 *  will get prepended to 'columns' before passing in to DataTable.
 *
 *  height: this can be one of several values: the string 'full',
 *  takes up the full height of the viewport; a function; or a string
 *  describing a fixed height. defaults to 'full'.
 *
 *  heightBuffer: used only when height is 'full'. This is the size,
 *  as an integer, in pixels, to subtract from viewport height, to use
 *  for the scrollY value.
 */

/* Hints for eslint: */
/* global window, alert, $ */

var SDBM = SDBM || {};

function relation (type) {
    if (type == "partial") {
        return "<span class='glyphicon glyphicon-asterisk'></span>";
    } else if (type == "possible") {
        return "<span class='glyphicon glyphicon-question-sign'></span>";
    } else {
        return "";
    }
}

(function () {

    "use strict";

    SDBM.Table = function(selector, options) {

        var defaults = {
            ajax: null,
            columns: null,
            fixedColumns: null,
            prependColumns: null,
            height: 'full',
            heightBuffer: 280,
            responsive: true,
            dom: '<"row"<"col-sm-5 mobile-center"li><"col-sm-7 text-right mobile-center"<"spinner"> p<"btn-group btn-table-tool"<"reset"><"wide"><"csv"><"columns">J>>>t'
        };

        this.options = $.extend({}, defaults, options);

        this.selector = selector;

        var sdbmTable = this;

        // NOTE: fields prefixed by 'sdbmss' are our own options, not
        // native to dataTables.
        this.columns = this.options.columns;

        if(options.prependColumns) {
            this.columns = [].concat(options.prependColumns).concat(this.columns);
        }

        // create THEAD elements using 'columns' data struct. dataTables
        // doesn't seem to be able to autogenerate this.
        $.each(this.columns, function(idx, column) {
            $(selector).find('thead tr').append("<th>" + column.name + "</th>");
        });

        var colOffset = options.prependColumns ? options.prependColumns.length : 0;
        var order = [[ 0 + colOffset, "desc" ]];
        if(options.order) {
            order = options.order;
            $.each(order, function(idx, orderItem) {
                // if it's a string column name, look it up
                var col = orderItem[0];
                if (col !== parseInt(col)) {
                    orderItem[0] = sdbmTable.getColumnIndex(col);
                }
            });
        }

        var scrollY = "";
        if(this.options.height === 'full') {
            scrollY = (this.getViewportHeight() - this.options.heightBuffer) + "px";
        } else if($.isFunction(this.options.height)) {
            scrollY = this.options.height();
        } else if(this.options.height) {
            scrollY = this.options.height;
        }

        this.dataTable = $(selector).DataTable({
            // we MUST set autoWidth=false to prevent a layout quirk that
            // prevents the 1st radio button (any form inputs containing
            // state in the 1st row, really) in the table from rendering
            // properly.
            // https://datatables.net/forums/discussion/24675/radio-button-checked-problem
            // 
            // saves things like sorting, column visibility, etc. in localstorage
            stateSave: true,
            autoWidth: false,
            ajax: function (dt_params, callback, settings) {
                //console.log('table ajax');
                options.ajax(sdbmTable, dt_params, callback, settings);
            },
            /*colVis: {
                "buttonText": "<span class='glyphicon glyphicon-option-horizontal'></span>"
            },*/
            columns: this.columns,
            language: {
                "emptyTable": "There are no records to display.",
                info:"Showing _START_ to _END_ of _TOTAL_ records",infoEmpty:"Showing 0 to 0 of 0 records",infoFiltered:"(filtered from _MAX_ total records)",
            },
            lengthMenu: [50, 100, 200, 500],
            order: order,
            rowCallback: function(row, data) {
                /*
                 * We have the following requirements for column widths:
                 *
                 * 1) reasonable initial col width even if there's no data
                 * for all cells in the column (because subsequent ajax
                 * calls may load data into it).
                 *
                 * 2) text in cells should no wrap and not overflow (this
                 * is controlled by our custom css rules).
                 *
                 * 3) the resize extension should work (ie manually
                 * resized widths should 'stick'), regardless of however
                 * we set the initial widths.
                 *
                 * I wasn't able to do all of these things with
                 * dataTables' built-in mechanisms for setting column
                 * widths. This solution here does satisfy all the above.
                 * We set min-width and max-width on TD elements (NOT TH),
                 * which has the effect of constraining TH widths as
                 * calculated by dataTables.
                 */
                $('td', row).each(function (idx, e) {
                    var opts = sdbmTable.columns[idx];
                    if(opts.sdbmssMinWidthImportant) {
                        $(e).css("min-width", opts.sdbmssMinWidthImportant);  //DISABLED sdbmssMinWidth
                    } else if (opts.sdbmssMinWidth) {
                        $(e).css("min-width", opts.sdbmssMinWidth);  //DISABLED sdbmssMinWidth                        
                    }
                    if(opts.sdbmssMaxWidthImportant) {
                        $(e).css("max-width", opts.sdbmssMaxWidthImportant);  //DISABLED sdbmssMaxWidth
                    } else if (opts.sdbmssMaxWidth) {
                        $(e).css("max-width", opts.sdbmssMaxWidth);  //DISABLED sdbmssMinWidth                        
                    }
                });
            },
            scrollX: true,
            scrollY: scrollY, //false,
            scrollCollapse: false,
            colReorder: false,
            colResize: true,

            // extensions get activated via these codes in 'dom' option
            // J = colResize
            // R = colReorder
            // C = show/hide columns widget
            // l = length ('show N entries')
            // r = processing display element
            // t = the table itself
            // i = information summary
            // p = pagination control
            dom: this.options.dom,
            serverSide: true
        });
    
        var the_table = this.dataTable;
        $('.wide').replaceWith('<a id="widescreen" class="btn btn-default" title="Widescreen View"><span class="glyphicon glyphicon-resize-full"></span></a>');
        $('#widescreen').click( function () {
            $("#main-container").toggleClass('container-fluid').toggleClass('container');
            $("#widescreen > span").toggleClass('glyphicon-resize-small').toggleClass('glyphicon-resize-full');
            if ($('#main-container').hasClass('container-fluid')) {
                $('.redundant-container').addClass('container');
            } else {
                $('.redundant-container').removeClass('container'); 
            }
            //$('.dataTables_scrollHeadInner').toggleClass('full-width');
            //$('.sdbm-table').toggleClass('full-width');
            //$('.search_results').toggleClass('full-width');
        });

        //$(".mapmode").replaceWith($("<a href='' class='btn btn-default'><span class='glyphicon glyphicon-picture'></span></a>"));
        
        $('.spinner').replaceWith('<span id="spinner" style="display: none;"><img alt="working..." src="' + $("#spinner-src").attr('src') + '"> loading...</span>');
        $('.csv').replaceWith('<a id="export-csv" class="btn btn-default" title="Export to CSV"><span class="glyphicon glyphicon-floppy-save"></span></a>');
        $('.columns').replaceWith('<div class="btn-group">' + 
            '<a class="btn btn-default dropdown-toggle" title="Show/Hide Columns" data-toggle="dropdown"><span class="glyphicon glyphicon-edit"></span></a>' +
            '<div id="column-control" class="dropdown-menu list-group">' +
            '</div>' +
            '</div>'
        );
        $('.reset').replaceWith('<a id="reset-columns" class="btn btn-default" title="Reset Table"><span class="glyphicon glyphicon-erase"></span></a>');
        $("#reset-columns").click( function () {
            localStorage["DataTables_search_results_" + window.location.pathname] = "";
            window.location = window.location.origin + window.location.pathname;
        });
        // new column hide/show function

        var dropdown = $('#column-control');
        var num_columns = the_table.columns()[0].length;
        for (var i = 0; i < num_columns; i++) {
            if (!sdbmTable.columns[i].never_show) {
                var option = $('<a class="dropdown-item list-group-item" index=' + i + '></a>');
                option.html(sdbmTable.columns[i].title);
                if (!the_table.column(i).visible()) {
                    option.addClass('disabled');
                }
                option.click( function (e) {
                    var n = Number($(this).attr('index'));
                    the_table.columns([n]).visible(!the_table.columns( [n]).visible()[0]);
                    $(this).toggleClass('disabled');
                });
                dropdown.append(option);
            }
        }

        if(this.options.fixedColumns) {
            new $.fn.dataTable.FixedColumns(this.dataTable, {
                leftColumns: this.options.fixedColumns
            });
        }
    };

    /**
     * Translates the common parameters from dataTables widget into URL
     * params for Blacklight search. This object knows how to do this for
     * params related to the table state (such as pagination); other
     * params need to be added by specialized uses of SDBM.Table.
     */
    SDBM.Table.prototype.translateParamsToBlacklight = function (dt_params) {
        return {
            draw: dt_params.draw,
            //page: (dt_params.start / dt_params.length) + 1,
            //per_page: dt_params.length,
            utf8: String.fromCharCode(0x2713),
            //search_field: "advanced",
            //sort: this.getSort(dt_params),
            offset: dt_params.start,
            limit: dt_params.length,
            order: this.getSort(dt_params),
            op: $('#search_op') ? $('#search_op').val() : 'all'
        };
    };

    SDBM.Table.prototype.getViewportHeight = function() {
        return $(window).height();
    };

    SDBM.Table.prototype.getSort = function(dt_params) {
        var sort = "";
        var sdbmTableInstance = this;
        $.each(dt_params.order, function(idx, order) {
            var columnDefinition = sdbmTableInstance.columns[order.column];
            var sortField = columnDefinition.sdbmssSortField;
            if(sortField) {
                if(sort) {
                    sort += ", ";
                }
                sort += sortField + " " + order.dir;
            } else {
                alert("ERROR: no sort field found for column, so using ID; fix this!");
            }
        });
        return sort;
    };

    SDBM.Table.prototype.getRowHeight = function() {
        return $(this.dataTable.rows().nodes().shift()).height();
    };

    SDBM.Table.prototype.getTableHeight = function() {
        return this.dataTable.rows().nodes().length * this.getRowHeight();
    };

    SDBM.Table.prototype.reload = function(callback) {
        //console.log('table reload');
        this.dataTable.ajax.reload(callback);
    };

    // given a row that's an Array, find the value at the index for the columnName
    SDBM.Table.prototype.getColumnIndex = function(columnName) {
        var columnNames = this.columns.map(function (item) { return item.title; });
        return columnNames.indexOf(columnName);
    };


    /*
     * Subclass of SDBM.Table for displaying Entries specifically.
     */
    SDBM.EntryTable = function(selector, options) {

        var sdbmTable = this;

        var defaultOptions = {
            // NOTE: fields prefixed by 'sdbmss' are our own options, not
            // native to dataTables.
            columns: [
                {
                    sdbmssMinWidth: "100px",
                    sdbmssMaxWidth: "100px",
                    sdbmssSortField: 'entry_id',
                    title: 'ID',
                    render: function (data, type, full, meta) {
                        if(data) {
                            if(full[sdbmTable.getColumnIndex("Is Approved")]) {
                                return '<a title="SDBM_' + data + '" href="/entries/' + data + '/" target="_blank">SDBM_' + data + '</a>';
                            } else {
                                return '<a title="SDBM_' + data + '" class="text-muted" href="/entries/' + data + '/" target="_blank">SDBM_' + data + '</a>';
                            }
                        }
                        return '';
                    }
                },
                {
                    sdbmssMinWidth: "120px",
                    sdbmssMaxWidth: "120px",
                    sdbmssSortField: 'manuscript_id',
                    title: 'Manuscript',
                    render: function (data, type, full, meta) {
                        if(data) {
                            return data.map(function (d) {
                                return '<a title="SDBM_MS_' + d.id + '" href="/manuscripts/' + d.id + '/" target="_blank">' + relation(d.relation) + ' SDBM_MS_' + d.id + '</a>';
                            }).join(", ");
                        }
                        return '';
                    }
                },
                {
                    title: 'User Groups',
                    sdbmssMinWidth: "100px",
                    sdbmssMaxWidth: "100px",
                    render: function (data, type, full, meta) {
                        var result = [];
                        for (var i = 0; i < data.length; i++) {
                            result.push('<a target="_blank" href="/groups/' + data[i][0] + '">' + data[i][1] + (data[i][2] ? ' <span class="text-muted">(editable)</span>' : '') + '</a>');
                        }
                        return result.join(", ");
                    },
                    orderable: false
                },
                {
                    sdbmssMinWidth: "100px",
                    sdbmssMaxWidth: "100px",
                    sdbmssSortField: 'source_date',
                    title: 'Source Date'
                },
                {
                    sdbmssMinWidthImportant: "350px",
                    sdbmssMaxWidthImportant: "350px",
                    sdbmssSortField: 'source_title',
                    title: 'Source Title'
                },
                {
                    sdbmssMinWidth: "100px",
                    sdbmssMaxWidth: "100px",
                    sdbmssSortField: 'catalog_or_lot_number',
                    title: 'Cat or Lot #'
                },
                {
                    sdbmssMinWidth: "150px",
                    sdbmssMaxWidth: "150px",
                    sdbmssSortField: 'institution',
                    title: 'Institution'
                },
                {
                    sdbmssMinWidth: "150px",
                    sdbmssMaxWidth: "150px",
                    sdbmssSortField: 'sale_selling_agent_flat',
                    title: 'Selling Agent',
                    //orderable: false
                },
                {
                    sdbmssMinWidth: "150px",
                    sdbmssMaxWidth: "150px",
                    sdbmssSortField: 'sale_seller_flat',
                    title: 'Seller',
                    //orderable: false
                },
                {
                    sdbmssMinWidth: "150px",
                    sdbmssMaxWidth: "150px",
                    sdbmssSortField: 'sale_buyer_flat',
                    title: 'Buyer',
                    //orderable: false
                },
                {
                    sdbmssMinWidth: "100px",
                    sdbmssMaxWidth: "100px",
                    sdbmssSortField: 'sale_sold',
                    title: 'Sold'
                },
                {
                    sdbmssMinWidth: "100px",
                    sdbmssMaxWidth: "100px",
                    sdbmssSortField: 'sale_date',
                    title: 'Sale Date',
                },
                {
                    sdbmssMinWidth: "100px",
                    sdbmssMaxWidth: "100px",
                    sdbmssSortField: 'sale_price',
                    title: 'Price'
                },
                {
                    sdbmssMinWidthImportant: "400px",
                    sdbmssMaxWidthImportant: "400px",
                    sdbmssSortField: 'title_flat',
                    title: 'Title'
                },
                {
                    sdbmssMinWidthImportant: "400px",
                    sdbmssMaxWidthImportant: "400px",
                    sdbmssSortField: 'author_flat',
                    title: 'Author'
                },
                {
                    sdbmssMinWidth: "200px",
                    sdbmssMaxWidth: "200px",
                    sdbmssSortField: 'manuscript_date_flat',
                    title: 'Date'
                },
                {
                    sdbmssMinWidth: "400px",
                    sdbmssMaxWidth: "400px",
                    sdbmssSortField: 'artist_flat',
                    title: 'Artist'
                },
                {
                    sdbmssMinWidth: "400px",
                    sdbmssMaxWidth: "400px",
                    sdbmssSortField: 'scribe_flat',
                    title: 'Scribe'
                },
                {
                    sdbmssMinWidth: "200px",
                    sdbmssMaxWidth: "200px",
                    sdbmssSortField: 'language_flat',
                    title: 'Language'
                },
                {
                    sdbmssMinWidth: "200px",
                    sdbmssMaxWidth: "200px",
                    sdbmssSortField: 'material_flat',
                    title: 'Material'
                },
                {
                    sdbmssMinWidth: "200px",
                    sdbmssMaxWidth: "200px",
                    sdbmssSortField: 'place_flat',
                    title: 'Place'
                },
                {
                    sdbmssMinWidth: "200px",
                    sdbmssMaxWidth: "200px",
                    sdbmssSortField: 'use_flat',
                    title: 'Use'
                },
                {
                    sdbmssMinWidth: "70px",
                    sdbmssMaxWidth: "70px",
                    sdbmssSortField: 'missing_authority_names',
                    title: 'Missing Names'
                },
                {
                    sdbmssMinWidth: "70px",
                    sdbmssMaxWidth: "70px",
                    sdbmssSortField: 'folios',
                    title: 'Folios'
                },
                {
                    sdbmssMinWidth: "70px",
                    sdbmssMaxWidth: "70px",
                    sdbmssSortField: 'num_columns',
                    title: 'Columns'
                },
                {
                    sdbmssMinWidth: "70px",
                    sdbmssMaxWidth: "70px",
                    sdbmssSortField: 'num_lines',
                    title: 'Lines'
                },
                {
                    sdbmssMinWidth: "70px",
                    sdbmssMaxWidth: "70px",
                    sdbmssSortField: 'height',
                    title: 'Height'
                },
                {
                    sdbmssMinWidth: "70px",
                    sdbmssMaxWidth: "70px",
                    sdbmssSortField: 'width',
                    title: 'Width'
                },
                {
                    sdbmssMinWidth: "70px",
                    sdbmssMaxWidth: "70px",
                    sdbmssSortField: 'alt_size',
                    title: 'Alt Size'
                },
                {
                    sdbmssMinWidth: "70px",
                    sdbmssMaxWidth: "70px",
                    sdbmssSortField: 'miniatures_fullpage',
                    title: 'Min Fl'
                },
                {
                    sdbmssMinWidth: "70px",
                    sdbmssMaxWidth: "70px",
                    sdbmssSortField: 'miniatures_large',
                    title: 'Min Lg'
                },
                {
                    sdbmssMinWidth: "70px",
                    sdbmssMaxWidth: "70px",
                    sdbmssSortField: 'miniatures_small',
                    title: 'Min Sm'
                },
                {
                    sdbmssMinWidth: "70px",
                    sdbmssMaxWidth: "70px",
                    sdbmssSortField: 'miniatures_unspec_size',
                    title: 'Min Un'
                },
                {
                    sdbmssMinWidth: "70px",
                    sdbmssMaxWidth: "70px",
                    sdbmssSortField: 'initials_historiated',
                    title: 'Init Hist'
                },
                {
                    sdbmssMinWidth: "70px",
                    sdbmssMaxWidth: "70px",
                    sdbmssSortField: 'initials_decorated',
                    title: 'Init Dec'
                },
                {
                    sdbmssMinWidth: "400px",
                    sdbmssMaxWidth: "400px",
                    title: 'Binding',
                    sdbmssSortField: 'binding'
                },
                {
                    sdbmssMinWidth: "400px",
                    sdbmssMaxWidth: "400px",
                    title: 'URL',
                    sdbmssSortField: 'manuscript_link',
                    render: function (data, type, full, meta) {
                        if(data) {
                            return '<a href="' + data + '" target="_blank">' + data + '</a>';
                        }
                        return '';
                    }
                },
                {
                    sdbmssMinWidthImportant: "400px",
                    sdbmssMaxWidthImportant: "400px",
                    title: 'Other Info',
                    sdbmssSortField: 'other_info'
                },
                {
                    sdbmssMinWidth: "500px",
                    sdbmssMaxWidth: "500px",
                    title: 'Provenance',
                    sdbmssSortField: 'provenance_flat'
                },
                {
                    sdbmssMinWidth: "130px",
                    sdbmssMaxWidth: "130px",
                    title: 'Added On',
                    sdbmssSortField: 'created_at'
                },
                {
                    sdbmssMinWidth: "130px",
                    sdbmssMaxWidth: "130px",
                    title: 'Added By',
                    sdbmssSortField: 'created_by'
                },
                {
                    sdbmssMinWidth: "130px",
                    sdbmssMaxWidth: "130px",
                    title: 'Last Updated',
                    sdbmssSortField: 'updated_at'
                },
                {
                    sdbmssMinWidth: "130px",
                    sdbmssMaxWidth: "130px",
                    title: 'Last Updated By',
                    sdbmssSortField: 'updated_at'
                },
                {
                    sdbmssMinWidth: "130px",
                    sdbmssMaxWidth: "130px",
                    title: 'Is Approved',
                    sdbmssSortField: 'approved'
                },
                {
                    sdbmssMinWidth: "130px",
                    sdbmssMaxWidth: "130px",
                    title: 'Deprecated',
                    sdbmssSortField: 'deprecated'
                },
                {
                    sdbmssMinWidth: "130px",
                    sdbmssMaxWidth: "130px",
                    title: 'Superceded By',
                    sdbmssSortField: 'superceded_by_id'
                },
                {
                    title: "Draft",
                    visible: false,
                    searchable: false,
                    never_show: true
                },
                {
                    title: "Can Edit",
                    visible: false,
                    searchable: false,
                    never_show: true
                },
                {
                    title: "BookmarkWatch",
                    visible: false,
                    searchable: false,
                    never_show: true
                }
            ]
        };

        SDBM.Table.call(this, selector, $.extend({}, defaultOptions, options));

        $(selector).on('draw.dt', function () {
            sdbmTable.dataTable.rows().nodes().each(function (row, idx, api) {
                var data = sdbmTable.dataTable.row(row).data();
                if (data[sdbmTable.getColumnIndex("Draft")]) {
                    $(row).addClass('info draft');
                } else if(!data[sdbmTable.getColumnIndex("Is Approved")]) {
                    $(row).addClass('warning unapproved');
                }

                $(row).children().each(function (idx, td) {
                    var titleValue = "SDBM_" + data[sdbmTable.getColumnIndex("ID")];
                    if(data[idx]) {
                        titleValue += ": " + data[idx];
                    }
                    $(td).attr("title", titleValue);
                });
            });
        });

        $(selector).on('click', 'tr', function (event) {
            // don't select if a link inside table was clicked
            if(event.target.tagName !== 'A') {
                $(event.currentTarget).toggleClass('selected');
            }
        });

    };

    SDBM.EntryTable.prototype = Object.create(SDBM.Table.prototype);

    SDBM.EntryTable.prototype.getSort = function(dt_params) {
        var sort = SDBM.Table.prototype.getSort.call(this, dt_params);
        if(!sort) {
            sort = "entry_id desc";
        }
        return sort;
    };

    /**
     * Callers of SDBM.EntryTable can call this in their implementation of
     * the 'ajax' function option.
     */
    SDBM.EntryTable.prototype.searchAndUpdateTable = function(params, dtCallback, ajaxOptions) {
        var sdbmTableInstance = this;

        var defaults = {
            url: '/entries.json',
            data: params,
            success: function(data, textStatus, jqXHR) {
                if(!data.error) {
                    $(".dataTables_scrollBody").scrollTop(0);
                    // when paging, we probably don't want to reset horiz scroll
                    // $(".dataTables_scrollBody").scrollLeft(0);
                    data.data = data.results.map(function (result) {
                        return [
                            result.id,
                            result.manuscript,
                            result.groups,
                            result.source_date,
                            result.source_title,
                            result.source_catalog_or_lot_number,
                            result.institution,
                            result.sale_selling_agent,
                            result.sale_seller_or_holder,
                            result.sale_buyer,
                            result.sale_sold,
                            result.sale_date,
                            result.sale_price,
                            result.titles,
                            result.authors,
                            result.dates,
                            result.artists,
                            result.scribes,
                            result.languages,
                            result.materials,
                            result.places,
                            result.uses,
                            result.missing_authority_names,
                            result.folios,
                            result.num_columns,
                            result.num_lines,
                            result.height,
                            result.width,
                            result.alt_size,
                            result.miniatures_fullpage,
                            result.miniatures_large,
                            result.miniatures_small,
                            result.miniatures_unspec_size,
                            result.initials_historiated,
                            result.initials_decorated,
                            result.manuscript_binding,
                            result.manuscript_link,
                            result.other_info,
                            result.provenance,
                            result.created_at,
                            result.created_by,
                            result.updated_at,
                            result.updated_by,
                            result.approved,
                            result.deprecated,
                            result.superceded_by_id,
                            result.draft,
                            result.can_edit,
                            result.bookmarkwatch
                        ];
                    });
                    
                    data.recordsTotal = data.total;
                    data.recordsFiltered = data.total;

                    // pad data with null entries so that columns are aligned
                    var columnsToPrepend = [];
                    if(sdbmTableInstance.options.prependColumns) {
                        for(var i = 0; i < sdbmTableInstance.options.prependColumns.length; i++) {
                            columnsToPrepend.push(null);
                        }
                        data.data.forEach(function (item) {
                            item.unshift.apply(item, columnsToPrepend);
                        });
                    }

                    dtCallback(data);
                } else {
                    alert("An error occurred fetching search results: " + data.error);
                }
            },
            error: function() {
                SDBM.showErrorModal("#modal", "An error occurred fetching search results");
            }
        };

        var options = $.extend({}, defaults, ajaxOptions);

        $.ajax(options);
    };

}());
