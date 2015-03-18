
/*
 * Table widget for viewing Entries. This is used in a few different
 * places, and needs to be somewhat customizable.
 * 
 * selector = jquery selector string specifying the table element
 * options = object containing the following keys:
 *
 *  ajax: callback used by SDBMTable to fetch results and populated
 *  table. This has the signature: function (sdbmTable, dt_params,
 *  callback, settings)
 *
 *  order: this gets passed to datatable for its 'order' option,
 *  except that we also translate column name strings to integer
 *  indexes.

 *  prependColumns: array of objects describing column options, to
 *  pass to DataTable.
 * 
 *  fullHeight: if true, takes up the full height of the
 *  viewport. defaults to true.
 *
 */
function SDBMTable(selector, options) {
    
    this.options = $.extend({}, {
        // defaults
        ajax: null,
        prependColumns: null,
        fullHeight: true
    }, options);

    this.table_height_buffer = 360;

    this.selector = selector;

    var sdbmTable = this;

    // NOTE: fields prefixed by 'sdbmss' are our own options, not
    // native to dataTables.
    this.columnOptions = [
        {
            sdbmssMinWidth: "100px",
            sdbmssSortField: 'entry_id',
            title: 'ID',
            render: function (data, type, full, meta) {
                if(data) {
                    return '<a href="/entries/' + data + '/" target="_blank">SDBM_' + data + '</a>';
                }
                return '';
            }
        },
        {
            sdbmssMinWidth: "100px",
            sdbmssSortField: 'manuscript_id',
            title: 'Manuscript',
            render: function (data, type, full, meta) {
                if(data) {
                    return '<a href="/manuscripts/' + data + '/edit/" target="_blank">SDBM_MS_' + data + '</a>';
                }
                return '';
            }
        },
        {
            sdbmssMinWidth: "100px",
            sdbmssSortField: 'source_date',
            title: 'Source Date'
        },
        {
            sdbmssMaxWidth: "350px",
            sdbmssSortField: 'source_title',
            title: 'Source Title'
        },
        {
            sdbmssMinWidth: "100px",
            sdbmssSortField: 'catalog_or_lot_number',
            title: 'Cat or Lot #'
        },
        {
            sdbmssMinWidth: "150px",
            sdbmssSortField: 'transaction_selling_agent',
            title: 'Selling Agent'
        },
        {
            sdbmssMinWidth: "150px",
            sdbmssSortField: 'transaction_seller',
            title: 'Seller'
        },
        {
            sdbmssMinWidth: "150px",
            sdbmssSortField: 'transaction_buyer',
            title: 'Buyer'
        },
        {
            sdbmssMinWidth: "100px",
            sdbmssSortField: 'transaction_sold',
            title: 'Sold'
        },
        {
            sdbmssMinWidth: "100px",
            sdbmssSortField: 'transaction_price',
            title: 'Price'
        },
        {
            sdbmssMinWidth: "200px",
            sdbmssMaxWidth: "400px",
            sdbmssSortField: 'title_flat',
            title: 'Title'
        },
        {
            sdbmssMinWidth: "200px",
            sdbmssMaxWidth: "400px",
            sdbmssSortField: 'author_flat',
            title: 'Author'
        },
        {
            sdbmssMinWidth: "100px",
            sdbmssMinWidth: "200px",
            sdbmssSortField: 'manuscript_date_flat',
            title: 'Date'
        },
        {
            sdbmssMinWidth: "200px",
            sdbmssMaxWidth: "400px",
            sdbmssSortField: 'artist_flat',
            title: 'Artist'
        },
        {
            sdbmssMinWidth: "200px",
            sdbmssMaxWidth: "400px",
            sdbmssSortField: 'scribe_flat',
            title: 'Scribe'
        },
        {
            sdbmssMinWidth: "100px",
            sdbmssMaxWidth: "200px",
            sdbmssSortField: 'language_flat',
            title: 'Language'
        },
        {
            sdbmssMinWidth: "100px",
            sdbmssMaxWidth: "200px",
            sdbmssSortField: 'material_flat',
            title: 'Material'
        },
        {
            sdbmssMinWidth: "100px",
            sdbmssMaxWidth: "200px",
            sdbmssSortField: 'place_flat',
            title: 'Place'
        },
        {
            sdbmssMinWidth: "100px",
            sdbmssMaxWidth: "200px",
            sdbmssSortField: 'use_flat',
            title: 'Use'
        },
        {
            sdbmssMinWidth: "70px",
            sdbmssSortField: 'folios',
            title: 'Folios'
        },
        {
            sdbmssMinWidth: "70px",
            sdbmssSortField: 'num_columns',
            title: 'Columns'
        },
        {
            sdbmssMinWidth: "70px",
            sdbmssSortField: 'num_lines',
            title: 'Lines'
        },
        {
            sdbmssMinWidth: "70px",
            sdbmssSortField: 'height',
            title: 'Height'
        },
        {
            sdbmssMinWidth: "70px",
            sdbmssSortField: 'width',
            title: 'Width'
        },
        {
            sdbmssMinWidth: "70px",
            sdbmssSortField: 'alt_size',
            title: 'Alt Size'
        },
        {
            sdbmssMinWidth: "70px",
            sdbmssSortField: 'miniatures_fullpage',
            title: 'Min Fl'
        },
        {
            sdbmssMinWidth: "70px",
            sdbmssSortField: 'miniatures_large',
            title: 'Min Lg'
        },
        {
            sdbmssMinWidth: "70px",
            sdbmssSortField: 'miniatures_small',
            title: 'Min Sm'
        },
        {
            sdbmssMinWidth: "70px",
            sdbmssSortField: 'miniatures_unspec_size',
            title: 'Min Un'
        },
        {
            sdbmssMinWidth: "70px",
            sdbmssSortField: 'initials_historiated',
            title: 'Init Hist'
        },
        {
            sdbmssMinWidth: "70px",
            sdbmssSortField: 'initials_decorated',
            title: 'Init Dec'
        },
        {
            sdbmssMinWidth: "400px",
            sdbmssMaxWidth: "400px",
            title: 'Binding',
            orderable: false
        },
        {
            sdbmssMinWidth: "400px",
            sdbmssMaxWidth: "400px",
            title: 'URL',
            orderable: false,
            render: function (data, type, full, meta) {
                if(data) {
                    return '<a href="' + data + '" target="_blank">' + data + '</a>';
                }
                return '';
            }
        },
        {
            sdbmssMinWidth: "400px",
            sdbmssMaxWidth: "400px",
            title: 'Other Info',
            orderable: false
        },
        {
            sdbmssMinWidth: "500px",
            sdbmssMaxWidth: "500px",
            title: 'Provenance',
            orderable: false
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
            title: 'Last Modified',
            sdbmssSortField: 'updated_at'
        },
        {
            sdbmssMinWidth: "130px",
            sdbmssMaxWidth: "130px",
            title: 'Last Modified By',
            sdbmssSortField: 'updated_at'
        },
        {
            sdbmssMinWidth: "130px",
            sdbmssMaxWidth: "130px",
            title: 'Is Approved',
            sdbmssSortField: 'approved'
        }
    ];

    if(options.prependColumns) {
        this.columnOptions = [].concat(options.prependColumns).concat(this.columnOptions);
    }
    
    // we have to create TH elements before dataTable init, otherwise
    // col widths are messed up and drag-resizing is broken. it's
    // possible I need additional option(s) for having dataTable
    // properly create the THs but I don't know what they could be.
    $.each(this.columnOptions, function(idx, column) {
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
    
    var scrollY = this.options.fullHeight ? (this.getViewportHeight() - this.table_height_buffer) + "px" : "";

    this.dataTable = $(selector).DataTable({
        // we MUST set autoWidth=false to prevent a layout quirk that
        // prevents the 1st radio button (any form inputs containing
        // state in the 1st row, really) in the table from rendering
        // properly.
        // https://datatables.net/forums/discussion/24675/radio-button-checked-problem
        autoWidth: false,
        ajax: function (dt_params, callback, settings) {
            options.ajax(sdbmTable, dt_params, callback, settings);
        },
        columns: this.columnOptions,
        language: {
            "emptyTable": "No records found for search query."
        },
        lengthMenu: [50, 100, 200, 500],
        order: order,
        rowCallback: function( row, data ) {
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
                var opts = sdbmTable.columnOptions[idx];
                if(opts.sdbmssMinWidth) {
                    $(e).css("min-width", opts.sdbmssMinWidth);
                }
                if(opts.sdbmssMaxWidth) {
                    $(e).css("max-width", opts.sdbmssMaxWidth);
                }
            });
        },
        scrollX: true,
        scrollY: scrollY,
        scrollCollapse: false,
        // extensions get activated via these codes in sDOM
        // J = colResize
        // R = colReorder
        sDom: 'C<"clear"><"H"lr>JRt<"F"ip>',
        serverSide: true
    });

    // this extension for fixed columns tends to mess up table redraws
    // (col headers get misaligned with col data), so we've disabled
    // it for now...
    /*
    new $.fn.dataTable.FixedColumns(table, {
        "leftColumns": 2
    });
    */

    $(selector).on('draw.dt', function () {
        sdbmTable.dataTable.rows().nodes().each(function (row, idx, api) {
            var data = sdbmTable.dataTable.row(row).data();
            $(row).attr("title", "SDBM_" + data[sdbmTable.getColumnIndex("ID")]);
        });
    });

}

/**
 * Translates the common parameters from dataTables widget into URL
 * params for Blacklight search. This object knows how to do this for
 * params related to the table state (such as pagination); other
 * params need to be added by specialized uses of SDBMTable.
 */
SDBMTable.prototype.translateParamsToBlacklight = function (dt_params) {
    return {
        draw: dt_params.draw,
        page: (dt_params.start / dt_params.length) + 1,
        per_page: dt_params.length,
        utf8: String.fromCharCode(0x2713),
        search_field: "advanced",
        sort: this.getSort(dt_params)
    };
};

SDBMTable.prototype.getViewportHeight = function() {
    return $(window).height();
};

SDBMTable.prototype.getSort = function(dt_params) {
    var sort = "";
    var sdbmTableInstance = this;
    $.each(dt_params.order, function(idx, order) {
        var columnDefinition = sdbmTableInstance.columnOptions[order.column];
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
    if(!sort) {
        sort = "entry_id desc";
    }
    return sort;
};

SDBMTable.prototype.getRowHeight = function() {
    return $(this.dataTable.rows().nodes().shift()).height();
};

SDBMTable.prototype.getTableHeight = function() {
    return this.dataTable.rows().nodes().length * this.getRowHeight();
};

SDBMTable.prototype.reload = function() {
    this.dataTable.ajax.reload();
};

// given a row that's an Array, find the value at the index for the columnName
SDBMTable.prototype.getColumnIndex = function(columnName) {
    var columnNames = this.columnOptions.map(function (item) { return item.title; });
    return columnNames.indexOf(columnName);
};

SDBMTable.prototype.searchAndUpdateTable = function(params, dtCallback, ajaxOptions) {
    var sdbmTableInstance = this;
    
    var defaults = {
        url: '/admin_search.json',
        data: params,
        success: function(data, textStatus, jqXHR) {
            if(!data.error) {
                $(".dataTables_scrollBody").scrollTop(0);
                // when paging, we probably don't want to reset horiz scroll
                // $(".dataTables_scrollBody").scrollLeft(0);

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
            // TODO: fill this out
            alert("An error occurred fetching search results");
        }
    };
    
    var options = $.extend({}, defaults, ajaxOptions);

    $.ajax(options);
};
