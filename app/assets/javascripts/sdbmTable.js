
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

    // NOTE: blSortField is our own custom attribute used to key
    // columns to their solr field in blacklight for sorting
    this.columnOptions = [
        {
            title: 'ID',
            blSortField: 'entry_id'
        },
        {
            title: 'Manuscript',
            blSortField: 'manuscript_id'
        },
        {
            title: 'Source Date',
            blSortField: 'source_date'
        },
        {
            title: 'Source Title',
            blSortField: 'source_title'
        },
        {
            title: 'Cat or Lot #',
            blSortField: 'catalog_or_lot_number'
        },
        {
            title: 'Seller Agent',
            blSortField: 'transaction_seller_agent'
        },
        {
            title: 'Seller',
            blSortField: 'transaction_seller'
        },
        {
            title: 'Buyer',
            blSortField: 'transaction_buyer'
        },
        {
            title: 'Sold',
            blSortField: 'transaction_sold'
        },
        {
            title: 'Price',
            blSortField: 'transaction_price'
        },
        {
            title: 'Title',
            blSortField: 'title_flat'
        },
        {
            title: 'Author',
            blSortField: 'author_flat'
        },
        {
            title: 'Date',
            blSortField: 'manuscript_date_flat'
        },
        {
            title: 'Artist',
            blSortField: 'artist_flat'
        },
        {
            title: 'Scribe',
            blSortField: 'scribe_flat'
        },
        {
            title: 'Language',
            blSortField: 'language_flat'
        },
        {
            title: 'Material',
            blSortField: 'material_flat'
        },
        {
            title: 'Use',
            blSortField: 'use_flat'
        },
        {
            title: 'Folios',
            blSortField: 'folios'
        },
        {
            title: 'Columns',
            blSortField: 'num_columns'
        },
        {
            title: 'Lines',
            blSortField: 'num_lines'
        },
        {
            title: 'Height',
            blSortField: 'height'
        },
        {
            title: 'Width',
            blSortField: 'width'
        },
        {
            title: 'Alt Size',
            blSortField: 'alt_size'
        },
        {
            title: 'Min Fl',
            blSortField: 'miniatures_fullpage'
        },
        {
            title: 'Min Lg',
            blSortField: 'miniatures_large'
        },
        {
            title: 'Min Sm',
            blSortField: 'miniatures_small'
        },
        {
            title: 'Min Un',
            blSortField: 'miniatures_unspec_size'
        },
        {
            title: 'Init Hist',
            blSortField: 'initials_historiated'
        },
        {
            title: 'Init Dec',
            blSortField: 'initials_decorated'
        },
        {
            title: 'Binding',
            "orderable": false
        },
        {
            title: 'URL',
            "orderable": false,
            "render": function (data, type, full, meta) {
                if(data) {
                    return '<a href="' + data + '" target="_blank">' + data + '</a>';
                }
                return '';
            }
        },
        {
            title: 'Other Info',
            "orderable": false
        },
        {
            title: 'Provenance',
            "orderable": false
        },
        {
            title: 'Added On',
            blSortField: 'created_at'
        },
        {
            title: 'Added By',
            blSortField: 'created_by'
        },
        {
            title: 'Last Modified',
            blSortField: 'updated_at'
        },
        {
            title: 'Last Modified By',
            blSortField: 'updated_at'
        },
        {
            title: 'Is Approved',
            blSortField: 'approved'
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

    var initialOrderColumn = 1;
    if(options.prependColumns) {
        initialOrderColumn = options.prependColumns.length;
    }
    
    var scrollY = this.options.fullHeight ? (this.getViewportHeight() - this.table_height_buffer) + "px" : "";

    this.dataTable = $(selector).DataTable({
        ajax: function (dt_params, callback, settings) {
            options.ajax(sdbmTable, dt_params, callback, settings);
        },
        columns: this.columnOptions,
        language: {
            "emptyTable": "No records found for search query."
        },
        lengthMenu: [50, 100, 200, 500],
        order: [[ initialOrderColumn, "desc" ]],
        scrollX: true,
        scrollY: scrollY,
        scrollCollapse: false,
        // extensions get activated via sDom codes
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
        var sortField = columnDefinition.blSortField;
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
