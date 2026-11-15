if (jQuery) (function($) {
    $.extend($.fn, {

        // toc table
        toc: function() {
            var _n_rows = 0;        // rows counter
            var _uniq_rows = 0;     // unique rows counter
            var _uniq_items = 0;    // unique items counter

            // structure describes row drag
            var row_drag = {
                dragHandle: "dragHandle",
                onDragClass: "dragTocRow",
                onDrop: function(table, row) {
                    var row_id = parseInt($(row).attr('row_id'));
                    var before_row_id = _n_rows;
                    var prev_row_id = -1;
                    $('tr.toc_row', tbl).each(function() {
                        var i = parseInt($(this).attr('row_id'));
                        if (row_id == prev_row_id)
                            before_row_id = i;
                        prev_row_id = i;
                    });
                    if (row_id != before_row_id && (1 + row_id) != before_row_id)
                        cmd_move_row(row_id, before_row_id);
                }
            };

            var showProductDetails = function(url_or_product_id, $tr) {
                var url;
                var product_id;
                if (url_or_product_id.match(/\?id=/))
                {
                    url = url_or_product_id;
                } else {
                    product_id = url_or_product_id;
                    url = '/product/view/?id=' + url_or_product_id;
                }
                var productDetails = $('#product-details-dialog');

                if (productDetails.length == 0) {
                    productDetails = $('<div id="product-details-dialog" />');
                    $('#toc').after(productDetails);
                    productDetails.bs_dialog({
                        autoOpen: false,
                        bgiframe: true
                    });

                }

                productDetails
                    .html('<img src="/css/images/spinner.gif" alt="" />')
                    .dialog('option', 'title', 'Loading Product Details')
                    .dialog('option', 'width', 640)
                    .dialog('option', 'height', 80)
                    .bs_dialog_open();

                $.fn.toc.ajax({
                    url: url,
                    data: { ajax: 1 },
                    success: function(html) {
                        var productDetails = $('#product-details-dialog');
                        if (productDetails.length) {

                            // special method to resize internal div after whole dialog resize
                            var resize_dialog_area = function() {
                                var $area = $('.section', productDetails);
                                var c = productDetails.parents('div.ui-dialog:first');
                                $area
                                    .width(c.width() - 20)
                                    .height(c.height() - 80);
                            };

                            productDetails
                                .dialog('close')
                                .html('<div class="section"><div>' + html + '</div></div>')
                                .dialog('option', 'title', 'Product Details')
                                .dialog('option', 'width', 640)
                                .dialog('option', 'height', 495)
                                .dialog('option', 'open', function(event, ui) {
                                    resize_dialog_area();
                                })
                                .dialog('option', 'resizeStop', function(event, ui) {
                                    resize_dialog_area();
                                })
                                .dialog('option', 'buttons', {
                                    "Close": function() {
                                        $(this).dialog('close');
                                    }
                                })
                            //.bs_dialog_open()
                                ;

                            var row_id = $tr.attr('row_id');

                            var checkIfExists = function(obj) {
                                if (item_exists(row_id, obj.val(), 'document')) {
                                    obj.attr('checked', 'checked');
                                } else
                                    obj.removeAttr('checked');
                            }

                            if ($.bs.can_write_file())
                                $('#product-details-dialog .groupChk').each(function() {
                                    var $this = $(this);
                                    var $parent = $this.parent();
                                    var item_row = find_item_row($this.val(), 'document');
                                    if (item_row > -1 && item_row != row_id) {
                                        $this.attr('disabled', 'disabled');
                                    } else {
                                        var itemOpCallback = function() {
                                            $parent.removeClass('ajax');
                                            checkIfExists($this);
                                        };

                                        $this.click(function() {
                                            $parent.addClass('ajax');
                                            if (item_exists(row_id, $this.val(), 'document')) {
                                                remove_item($tr, $this.val(), 'document', itemOpCallback);
                                            } else {
                                                add_new_item($tr, $this.val(), 'document', itemOpCallback);
                                            }
                                        });
                                        checkIfExists($this);
                                    }
                                });

                            var rpform = $('#related-products-form');
                            rpform.append('<input type="hidden" name="package_id" value="' + package_id + '" />');
                            rpform.submit(function() {
                                if (!$.bs.can_write_file())
                                    return false;
                                if ($('input[name="related_product"]:checked').length == 0)
                                    return false;
                                $.ajax({
                                    url: rpform.attr('action'),
                                    type: 'GET',
                                    cache: false,
                                    dataType: 'json',
                                    data: rpform.serialize() + '&ajax=1',
                                    beforeSend: function() {
                                        rpform.addClass('ajax');
                                    },
                                    success: function(json) {
                                        rpform.removeClass('ajax');
                                        var data = json.Result;
                                        var file;
                                        for (var i = 0; i < data.row.items.length; i++)
                                            if (data.row.items[i].object_id == data.file.id)
                                            file = data.row.items[i];

                                        add_existing_item(row_id, file);

                                        if (data.old_file) {
                                            $tr.find('[href=' + data.old_file.url + ']').parents('.toc_item').remove();
                                            toc_table[row_id].items = data.row.items;
                                            _update_items_ids($tr.find('.toc_items'))
                                        }
                                    }
                                });
                                return false;
                            });

                            productDetails
                                .bs_dialog_open();
                            resize_dialog_area();
                        }
                    }
                });
            };

            // handler of row menu items
            var on_row_menu_click = function(event) {
                var menu_element = event.target;
                var cmd = $(menu_element).attr('cmd');
                var isEndEvent = true;
                switch (cmd) {
                    case 'delete_row':
                        if ($.bs.can_write_file())
                            cmd_remove_row($(menu_element).parents('tr:first').attr('uniq_id'));
                        break;
                    case 'view_product':
                        showProductDetails($(menu_element).attr('href'), $(menu_element).parents('tr:first'));
                        return false;
                        break;
                    default:
                        isEndEvent = false;
                }
                if (isEndEvent) {
                    event.stopPropagation();
                    event.preventDefault();
                }
                return false;
            }

            // add row menu for specified cell
            var _add_row_menu = function(row, product_id) {
                if (product_id === 0 && !$.bs.can_write_file())
                    return;
                var cell = $('td:first', row);
                var menu = "<ul>";
                if (product_id != 0) {
                    if ($.bs.can_write_file())
                        menu += '<li><a cmd="delete_row" uniq_row="' + $(row).attr('id') + '" href="toc">Delete Row</a></li>';
                    menu += '<li><a cmd="view_product" href="/product/view?id=' + product_id + '">View Product Details</a></li>';
                } else {
                    if ($.bs.can_write_file())
                        menu += '<li><a cmd="delete_row" uniq_row="' + $(row).attr('id') + '" href="toc">Delete Row</a></li>';
                }
                menu += "</ul>";

                $(cell).html(menu);

                // popup/hode row menu
                $(cell)
                    .mouseover(function() { $('ul', this).show(); })
                    .mouseout(function() { $('ul', this).hide(); });

                // click row menu item
                $('li a', cell).click(on_row_menu_click);

            }

            // add existing in logic model item to html
            // @param ul the list for adding new existed item to
            // @param item_id logical id of this item in its row
            // @param item_data
            // @product_id id of the product of this row, if any (product_submitted_id)
            // @return new item (li)
            var add_item = function(ul, item_id, item_data, product_id) {
                var row = $(ul).parents('tr:first');
                var row_id = $(row).attr('row_id');
                var uniq_row = $(row).attr('uniq_id');

                var li = document.createElement('li');
                var display_name = item_data.title;
                if (product_id
                     && item_data['shorttitle']
                     && item_data.is_product_document
                     && item_data.product_id == product_id) {
                    display_name = item_data.shorttitle;
                }
                $(li).appendTo($(ul))
                    .attr('uniq_row', uniq_row)
                    .attr('uniq_id', _uniq_items)
                    .attr('item_id', item_id)
                    .addClass('toc_item')
                    .addClass('toc_item_before')

                $(li).html(
                        $.bs.get_template($.bs.can_write_file() ? 'toc_item' : 'toc_item_ro', {
                            name: display_name,
                            link: $.bs.get_link(item_data),
                            size: $.bs.get_size(item_data),
                            wrap: display_name && display_name.length > 30 ? '<br />' : ''
                        })
                    );

                if ($.bs.can_write_file()) {
                    $('a.deleteitem', li).click(function(event) {
                        remove_item($(this).parents('tr.toc_row:first'), item_data.id, item_data.type, null);
                        return false;
                    });

                    $('img.toc_item_menu', li).draggable({
                        helper: 'clone'
                    });

                    $(li).droppable({
                        accept: 'img.toc_item_menu',
                        hoverClass: 'toc_item_drop',
                        drop: function(event, ui) {
                            drop_item(null, li, ui);
                        }
                    });
                }

                _uniq_items++;
                return li;
            }

            var add_existing_item = function(row_id, item_data) {
                var row;
                if (toc_table.length - 1 < row_id || row_id < 0) // no such row added yet
                {
                    row_id = toc_table.length;
                    for (var i = toc_table.length; i <= row_id; ++i)
                        row = init_new_row();
                } else { // row is already added
                    row = $('tr.toc_row[row_id=' + row_id + ']', tbl)[0];
                }

                // add item to 
                var datarow = toc_table[row_id];
                datarow.items.push(item_data);

                add_item($('ul.toc_items', row),
                          datarow.items.length - 1,
                          item_data,
                          item_data['product_id'] ? item_data['product_id'] : 0);
            }
            var add_existing_row = function($row_data) {
                var row_id = $row_data.row_id;

                var row;
                if (toc_table.length - 1 < row_id) // no such row added yet
                {
                    for (var i = toc_table.length; i <= row_id; ++i)
                        row = init_new_row();
                } else { // row is already added
                    row = $('tr.toc_row[row_id=' + row_id + ']', tbl)[0];
                }

                var product_id = $row_data["product_submitted_id"];

                // add row menu
                if (product_id != 0 || $.bs.can_write_file())
                    $(cell).addClass('screw_menu');
                _add_row_menu(row, product_id);

                var items = $row_data.items;

                // add items to model
                var datarow = toc_table[row_id];
                datarow.items = items;

                // add items to view
                var ul = $('ul.toc_items', row);
                $('li', ul).remove();
                for (var i_item = 0; i_item < items.length; ++i_item) {
                    add_item(ul, i_item, items[i_item], product_id);
                }
                if ($.bs.can_write_file()) {
                    var cell = ul.parent();
                    cell.droppable({
                        accept: 'img.toc_item_menu',
                        hoverClass: 'toc_item_drop',
                        drop: function(event, ui) {
                            drop_item(row, null, ui);
                        }
                    });
                    if (items.length > 0)
                        cell.droppable('disable');
                }

                // add product submitted
                if (product_id) {
                    // add to model
                    datarow.product_submitted_id = product_id;
                    datarow.product_submitted = $row_data["product_submitted"];
                    datarow.manufacturer = $row_data["manufacturer"];

                    // add to view
                    $('td.c_product_submitted', row).text($row_data["product_submitted"]);
                    $('td.c_manufacturer', row).text($row_data["manufacturer"]);
                }
            }

            /// add new item to the toc logic model and to the html
            /// @param row the row to add item
            /// @param item_id id of document or file or package to add
            /// @param type 'document' or 'file'
            var add_new_item = function(row, item_id, type, callback) {
                var row_id = -1;
                if (row) {
                    row_id = $(row).attr('row_id');
                    row.children('.c_items').append($('#ajax_process'));
                    $('#ajax_process').show();
                }
                $.fn.toc.ajax({
                    url: "/jstoc/add_toc_item"
                    , dataType: 'json'
                    , type: 'GET'
                    , cache: false
                    , data: {
                        package_id: package_id
                        , row_id: row_id
                        , item_id: item_id
                        , type: type
                    }
                    , success: function(data) {
                        if (row)
                            $('#ajax_process').hide();

                        var files_add = [];

                        if ('ok' == data.Result.code) {
                            for (var i = 0; i < data.Result.rows.length; ++i) {
                                add_existing_row(data.Result.rows[i]);
                                var r = data.Result.rows[i];
                                for (var ii = 0; ii < r.items.length; ++ii)
                                    if (r.items[ii].type == 'file')
                                    files_add.push(r.items[ii].id);
                            }
                        }

                        // this auto-unchecks the checkboxes in the product details popup!:
                        //$('#placement_sidebar').trigger('update');
                        if (_edit_mode)
                            $('#ci_product_submitted').trigger('beforeEdit');

                        // switch droppables in row
                        if (row_id >= 0 && toc_table[row_id].items.length == 0) {
                            $('td.c_items', row).droppable('enable');
                        }

                        if ("function" == typeof callback)
                            callback(files_add);
                    } // success()
                });
            }

            // add html row by specified row data
            // @param row_data hash of params for the row or null for new empty row
            // @return new row
            var add_row = function(row_data) {

                //console.log( "add_row()" );

                // add html row
                var row = $(tbl)[0].insertRow(-1);
                $(row).addClass('toc_row');
                $(row).attr('uniq_id', _uniq_rows);
                $(row).attr('row_id', _n_rows);
                $(row).attr('row_type', 'data');

                // add menu cell (drag screw)
                var cell = row.insertCell(-1);
                $(cell).addClass($.bs.can_write_file() ? 'screw' : 'screw_ro')
                    .addClass('dragHandle')
                    .addClass('screw_img');
                var product_id = row_data == null ? 0 : row_data["product_submitted_id"];

                if (product_id != 0 || $.bs.can_write_file())
                    $(cell).addClass('screw_menu');
                _add_row_menu(row, product_id);

                // add data cells
                $(toc_columns).each(function(index, column) {
                    if (column.type == 'product_submitted_id')
                        return;
                    var cell = row.insertCell(-1);
                    $(cell).addClass('c_' + column.name);

                    if (column.type == 'items') {
                        var s = '<ul class="toc_items"></ul>';
                        $(cell).html(s);
                        var ul = $('ul', cell);
                        var items = row_data.items;
                        for (var i_item = 0; i_item < items.length; ++i_item) {
                            add_item(ul, i_item, items[i_item], row_data["product_submitted_id"]);
                        }
                        if (false && $.bs.can_write_file()) {
                            $(cell).droppable({
                                accept: 'img.toc_item_menu',
                                hoverClass: 'toc_item_drop',
                                drop: function(event, ui) {
                                    drop_item(row, null, ui);
                                }
                            });
                            if (items.length > 0)
                                $(cell).droppable('disable');
                        }
                    } else {
                        if (null != row_data)
                            $(cell).text(row_data[column.name]);
                    }

                    if ($.bs.can_write_file())
                    // edit row by click in any data cell
                        if (column.type != 'items')
                        $(cell).click(function() {
                            cmd_edit_row($(row), cell);
                        });
                });

                // increment rows counters
                _n_rows++;
                _uniq_rows++;

                if (_n_rows >= 4)
                    $('#table-action-bar2').show();

                return row;
            }

            // used to add brand new empty row
            var add_new_row = function(row_data) {
                var row = add_row(row_data);
                $(tbl).tableDnDUpdate(row_drag);
                return row;
            }

            /// returns number of items in specified row of logic toc talble or 0
            /// @param row_id index of row in the logic toc table
            var items_count = function(row_id) {
                if (typeof row_id == "undefined")
                    return 0;
                if (toc_table.length - 1 < row_id)
                    return 0;
                if (typeof toc_table[row_id] == "undefined")
                    return 0;
                if (typeof toc_table[row_id].items == "undefined")
                    return 0;
                return toc_table[row_id].items.length;
            }

            /// @return true if specified item (doc. or file) is in the specified row
            var item_exists = function(row_id, item_id, type) {
                //console.log( "item_exists: " + row_id + ' ' + item_id + ' ' + type );
                if (!items_count(row_id))
                    return false;

                var items = toc_table[row_id].items;
                var n = items.length;
                for (var i = 0; i < n; i++)
                    if (items[i].id == item_id && items[i].type == type)
                    return true;
                return false;
            }

            var find_item_row = function(item_id, type) {
                for (i = 0; i < toc_table.length; i++)
                    if (item_exists(i, item_id, type))
                    return i;

                return -1;
            }

            var remove_item = function(row, item_id, type, callback) {
                var id = -1;
                var row_id = -1;
                if (row) {
                    row_id = row.attr('row_id');
                    var items = toc_table[row_id].items;
                    var n = items.length;
                    for (var i = 0; i < n; i++) {
                        if (items[i].id == item_id && items[i].type == type)
                            id = i;
                    }
                } else {
                    var nr = toc_table.length;
                    for (var ir = 0; ir < nr; ir++) {
                        var items = toc_table[ir].items;
                        var n = items.length;
                        for (var i = 0; i < n; i++) {
                            if (items[i].id == item_id && items[i].type == type) {
                                id = i;
                                row_id = ir;
                                row = $('tr.toc_row[row_id=' + row_id + ']');
                            }
                        }
                    }
                }
                if (id == -1 || row_id == -1 || (!row))
                    return false;

                var ul = row.children('.c_items').children('ul.toc_items');

                //$(ul).children('li[item_id=' + id + ']').addClass('ajax');
                var save_src, save_img;
                save_img = $('img.toc_item_menu', $(ul).children('li[item_id=' + id + ']'));
                save_src = save_img.attr('src');
                save_img.attr('src', '/css/images/spinner.gif');

                $.fn.toc.ajax({
                    url: "/jstoc/remove_toc_item"
                    , dataType: 'json'
                    , type: 'GET'
                    , cache: false
                    , data: {
                        package_id: package_id,
                        row_id: row_id,
                        item_id: id
                    }
                    , success: function(data) {

                        //$(ul).children('li[item_id=' + id + ']').removeClass('ajax');
                        save_img.attr('src', save_src);

                        if ('ok' == data.Result) {
                            var ul = row.children('.c_items').children('ul.toc_items');
                            toc_table[row_id].items.splice(id, 1);
                            ul.children('li[item_id=' + id + ']').remove();
                            if (ul)
                                _update_items_ids(ul);
                        }
                        $('#placement_sidebar').trigger('update');
                        if (_edit_mode)
                            $('#ci_product_submitted').trigger('beforeEdit');
                        if ("function" == typeof callback)
                            callback();
                    }
                });

            }

            // it works in 2 modes:
            // 1: drop item to the same row: null, li, ui
            // 2: drop item to another row: dest_row, null, ui
            var drop_item = function(dest_row, li_before, ui) {
                // li item to drop
                var li_item = $(ui.draggable).parents('li:first');

                // table row of this item
                var row = $(li_item).parents('tr:first');
                if (!row)
                    return;

                // if the same row then use dest_row as row of the dest anchor item
                if (dest_row == null)
                    dest_row = $(li_before).parents('tr:first');

                var dest_row_id = $(dest_row).attr('row_id');
                var before_item_id = -1;
                var save_src, save_img;
                if (li_before != null) // if drop to the same row
                {
                    before_item_id = $(li_before).attr('item_id');
                    //$(li_before).addClass('ajax');
                    save_img = $('img.toc_item_menu', li_before);
                    save_src = save_img.attr('src');
                    save_img.attr('src', '/css/images/spinner.gif');
                } else { // drop to another row
                    before_item_id = toc_table[dest_row_id].items.length;
                    $('td.c_items', dest_row).addClass('ajax');
                }

                $.fn.toc.ajax({
                    url: "/jstoc/move_toc_item"
                    , dataType: 'json'
                    , type: 'GET'
                    , cache: false
                    , data: {
                        package_id: package_id
                        , row_id: $(row).attr('row_id')
                        , item_id: $(li_item).attr('item_id')
                        , dest_row_id: dest_row_id
                        , before_item_id: before_item_id
                    }
                    , success: function(data) {
                        if (li_before != null) {
                            //$(li_before).removeClass('ajax');
                            save_img.attr('src', save_src);
                        } else {
                            $('td.c_items', dest_row).removeClass('ajax');
                        }
                        if ('ok' == data.Result) {
                            var row_id = $(row).attr('row_id');
                            var dest_row_id = $(dest_row).attr('row_id');

                            // switch droppables in destination row
                            if (row_id != dest_row_id && toc_table[dest_row_id].items.length == 0) {
                                $('td.c_items', dest_row).droppable('disable');
                            }

                            // move item in the logic structure
                            var before_item_id = -1;
                            if (li_before != null && row_id == dest_row_id) // the same row
                            {
                                before_item_id = $(li_before).attr('item_id');
                            } else {
                                before_item_id = toc_table[dest_row_id].items.length; // another row
                            }
                            var item_id = $(li_item).attr('item_id');
                            toc_table[dest_row_id].items.splice(before_item_id, 0,
                                toc_table[row_id].items.splice(item_id, 1)[0]);

                            // move li in HTML
                            if (li_before == null || row_id != dest_row_id) {
                                $('ul.toc_items', dest_row).append(li_item);
                            } else {
                                if (before_item_id > item_id)
                                    $(li_before).after(li_item);
                                else
                                    $(li_before).before(li_item);
                            }

                            // update items indexes in html
                            _update_items_ids($('ul.toc_items', dest_row));
                            if (row_id != dest_row_id)
                                _update_items_ids($('ul.toc_items', row));

                            // switch droppables in source row
                            if (row_id >= 0 && toc_table[row_id].items.length == 0) {
                                $('td.c_items', row).droppable('enable');
                            }
                        }

                    }
                });

            }


            var _update_items_ids = function(ul) {
                var i = 0;
                $('li.toc_item', ul).each(function() {
                    $(this).attr('item_id', i++);
                });
            }
            var _update_rows_ids = function() {
                var i = 0;
                $('tr.toc_row', tbl).each(function() {
                    $(this).attr('row_id', i++);
                });
            }



            // edit row mode

            var _edit_mode = 0; // 0-no edit mode, 1-some row in edit mode
            var _edit_row = null;    // existed data row that is in edit mode for now

            // real switch the row to edit mode
            var _show_editor_row = function(row, cell) {
                if (1 == _edit_mode)
                    return 0;

                //console.log( "_show_editor_row" );

                _edit_row = row; // save data row to edit

                $(_edit_row).addClass("sel");   // add class for highlighting
                var i_row = parseInt($(_edit_row).attr('row_id'));    // get index of the row to edit

                // fix column width
                var widths = [];

                // get the widths
                $('th', tbl.get(0)).each(function(index, th) {
                    widths[index] = $(th).width();
                    //console.log( "w[" + index + "] = " + widths[index] );
                });
                // set the widths
                $('th', tbl.get(0)).each(function(index, th) {
                    $(th).attr('width', widths[index]);
                });
                // set fixed layout
                tbl.get(0).style.tableLayout = 'fixed';

                // copy columns values from data to editor row
                // remove static row html
                // copy inputs from hidden row to edit data row
                $(toc_columns).each(function(index, column) {

                    if (column.type == 'product_submitted_id' || column.type == 'items')
                        return;

                    var input = $('#ci_' + column.name);
                    var th = $('th.c_' + column.name);
                    var td = $(_edit_row).find('td.c_' + column.name);

                    // copy columns values from data to editor row
                    input.attr('value', eval('toc_table[i_row].' + column.name));

                    if (column.type == 'product_submitted')
                        $('#ci_product_submitted_id').attr('value', eval('toc_table[i_row].product_submitted_id'));

                    var width = th.width();

                    td.html('')               // remove static row html
                        .append(input);     // copy inputs from hidden row to edit data row

                    input.width(width - 12);
                });

                $('input.toc_edit').trigger('beforeEdit');

                // focus specified cell if it's provided or try to focus first one
                if (null != cell)
                    $('input', cell).focus_safe().select();
                else {
                    var input = $('input.toc_edit:first');
                    if (input)
                        input.focus_safe().select();
                }

                _edit_mode = 1;
                $('input.table-action-save').attr('disabled', '');
            }

            // real switch the editor row to view mode
            var _hide_editor_row = function() {
                if (0 == _edit_mode)
                    return 0;

                //alert('exit edit mode');
                //console.log( "_hide_editor_row" );
                $(_edit_row).removeClass("sel"); // remove highlighting
                var i_row = $(_edit_row).attr('row_id');

                // clear columns of editor row
                $(toc_columns).each(function(index, column) {
                    if (column.type == 'product_submitted_id' || column.type == 'items')
                        return;

                    var input = $('#ci_' + column.name).attr('value', '')
                        .width(10);

                    if (column.type == 'product_submitted')
                        $('#ci_product_submitted_id').attr('value', '');

                    $(row_editor).find('td.c_' + column.name)
                        .append(input);

                    $(_edit_row).find('td.c_' + column.name).text(toc_table[i_row][column.name]);

                });

                // disable fixed table layout, remove width attributes
                $('th', tbl.get(0)).each(function(index, th) {
                    $(th).removeAttr('width');
                });
                // set fixed layout
                tbl.get(0).style.tableLayout = 'auto';

                _edit_mode = 0;
                _edit_row = null;

                $('input.table-action-save').attr('disabled', 'disabled');
            }

            // @return 0-row is not modified or not in edit mode at all, 1-there are some changes in the editor row
            var _is_row_modified = function() {
                if (0 == _edit_mode)
                    return 0;
                var i_row = $(_edit_row).attr('row_id');
                var modified = 0;
                $(toc_columns).each(function(index, column) {
                    if (column.type == 'items')
                        return;
                    if (eval('toc_table[i_row].' + column.name) != $('#ci_' + column.name).attr('value'))
                        modified = 1;
                });
                return modified;
            }

            // @return null-no data to submit, hash of values with new data from editor
            var _get_editor_row_data = function() {
                if (0 == _edit_mode)
                    return null;
                var row_data = {};
                $(toc_columns).each(function(index, column) {
                    if (column.type == 'items')
                        return;
                    row_data[column.name] = $('#ci_' + column.name).val();
                });
                return row_data;
            }

            // @param on_submit - function to call on successful submit
            // @return 0-nothign to submit, 1-submitted
            // it may be called by user and by some other methods
            var submit_edit = function(on_submit) {
                if (0 == _edit_mode)
                    return 0;
                $('input.toc_edit').trigger('afterEdit');
                // do nothing if there is no changes
                if (!_is_row_modified()) {
                    _hide_editor_row();
                    return 0;
                }
                // get new data to submit
                var row_data = _get_editor_row_data();
                if (typeof (row_data) == 'undefined')
                    return 0;

                var i_row = $(_edit_row).attr('row_id');

                $('td:first', _edit_row).removeClass('screw_img').addClass('ajax');

                $.fn.toc.ajax({
                    url: "/jstoc/save_toc_row"
                    , dataType: 'json'
                    , type: 'GET'
                    , cache: false
                    , data: {
                        package_id: package_id
                        , row_id: i_row
                        , row: $.toJSON(row_data)
                    }
                    , success: function(data) {
                        $('td:first', _edit_row).removeClass('ajax').addClass('screw_img');
                        if ('ok' == data.Result.code) {
                            var leed_values = data.Result.leed_values;
                            // move new values to data
                            $(toc_columns).each(function(index, column) {
                                if (column.type == 'items')
                                    return;
                                if (column.type == 'product_submitted_id') {
                                    if (toc_table[i_row]['product_submitted_id'] != row_data['product_submitted_id'])
                                        _add_row_menu(_edit_row, row_data['product_submitted_id']);
                                }
                                if (typeof(leed_values[column.name]) != 'undefined')
                                    row_data[column.name] = leed_values[column.name];
                                toc_table[i_row][column.name] = row_data[column.name];
                            });

                            // move new values to cells
                            _hide_editor_row();

                            // call something to be called after success submit
                            if (on_submit != null)
                                on_submit();

                            return; // all is done. just return here.
                        }

                        _hide_editor_row(); // turn off edit mode, at least
                    }
                });
                return 1;
            }
            // called by user to cancel edit mode
            var cancel_edit = function() {
                _hide_editor_row();
            }

            // try to turn on edit mode for specified row
            // it may be called by user or by another method
            var cmd_edit_row = function(row, cell) {
                if ($(row).attr("row_id") == $(_edit_row).attr("row_id"))
                    return;
                if (0 == submit_edit(
                        function() { cmd_edit_row(row, cell); }
                    )
                ) {
                    _show_editor_row(row, cell);
                }
            }


            // initiate the process of insertion (adding) new empty row
            // then opening it in edit mode
            var cmd_add_row = function() {
                $('div#toc_add').addClass('ajax2');
                $.fn.toc.ajax({
                    url: "/jstoc/insert_toc_row"
                    , dataType: 'json'
                    , type: 'GET'
                    , cache: false
                    , data: {
                        package_id: package_id
                        , row_id: -1
                    }
                    , success: function(data) {
                        $('div#toc_add').removeClass('ajax2');
                        if ('ok' == data.Result) {
                            cmd_edit_row(init_new_row(), null);
                        }
                    }
                });
            }

            // add new empty row to logic model
            // then add new row to html table
            // return
            var init_new_row = function() {
                var data_row = {};
                // add data cells
                $(toc_columns).each(function(index, column) {
                    if (column.type == 'product_submitted_id') {
                        data_row['product_submitted_id'] = 0;
                        return;
                    }
                    else if (column.type == 'items') {
                        data_row['items'] = [];
                    } else {
                        data_row[column.name] = '';
                    }
                });
                toc_table[toc_table.length] = data_row;
                return add_new_row(data_row);
            }

            // remove row
            // it send request to the server on row delete
            // then it removes the row and update rows id's
            var cmd_remove_row = function(uniq_row_id) {
                var row = $('tr.toc_row[uniq_id=' + uniq_row_id + ']', tbl)[0];
                if (!row)
                    return;
                if (1 == _edit_mode)
                    _hide_editor_row();
                $('td:first', row).removeClass('screw_img').addClass('ajax');
                $.fn.toc.ajax({
                    url: "/jstoc/remove_toc_row"
                    , dataType: 'json'
                    , type: 'GET'
                    , cache: false
                    , data: {
                        package_id: package_id
                        , row_id: $(row).attr('row_id')
                    }
                    , success: function(data) {
                        $('td:first', row).removeClass('ajax').addClass('screw_img');
                        if ('ok' == data.Result) {

                            $(row).remove();
                            toc_table.splice($(row).attr('row_id'), 1);

                            // update rows id's
                            _n_rows--;
                            _update_rows_ids();

                            if (_n_rows < 4)
                                $('#table-action-bar2').hide();
                        }
                    }
                });

            }

            // !!! It doesn't used for now !!!
            // remove item
            // it send request to the server on item delete
            // then it removes the item and update items id's
            var cmd_remove_item = function(uniq_item) {
                var item = $('li.toc_item[uniq_id=' + uniq_item + ']', tbl)[0];
                if (!item)
                    return;
                var row = $(item).parents('tr:first');
                if (!row)
                    return;

                $(item).addClass('ajax');

                $.fn.toc.ajax({
                    url: "/jstoc/remove_toc_item"
                    , dataType: 'json'
                    , type: 'GET'
                    , cache: false
                    , data: {
                        package_id: package_id
                        , row_id: $(row).attr('row_id')
                        , item_id: $(item).attr('item_id')
                    }
                    , success: function(data) {
                        $(item).removeClass('ajax');
                        if ('ok' == data.Result) {
                            var ul = $(item).parents('ul:first');
                            toc_table[$(row).attr('row_id')].items.splice($(item).attr('item_id'), 1);
                            $(item).remove();
                            if (ul)
                                _update_items_ids(ul);
                        }
                    }
                });

            }

            // move row
            // it update rows id's
            // then send request to the server on row move
            // it doesn't need to move the html row because it's already moved
            var cmd_move_row = function(row_id, before_row_id) {
                _update_rows_ids();

                var row = $('tr[row_id=' + (before_row_id - (before_row_id > row_id ? 1 : 0)) + ']', tbl);
                $('td:first', row).removeClass('screw_img').addClass('ajax');

                $.fn.toc.ajax({
                    url: "/jstoc/move_toc_row"
                    , dataType: 'json'
                    , type: 'GET'
                    , cache: false
                    , data: {
                        package_id: package_id
                        , row_id: row_id
                        , before_row_id: before_row_id
                    }
                    , success: function(data) {
                        $('td:first', row).removeClass('ajax').addClass('screw_img');
                        if ('ok' == data.Result) {
                            // TODO:    if it's not ok then just refresh the page
                            //          then we need to move row back

                            // move row in the logic model
                            toc_table.splice(
                                before_row_id > row_id ? before_row_id - 1 : before_row_id,
                                0,
                                toc_table.splice(row_id, 1)[0]
                            );

                        }
                    }
                });

            }


            var defaultKeydownHandler = function(obj, event) {
                if (event.keyCode == 13) // enter
                {
                    submit_edit(null);
                    return;
                }
                if (event.keyCode == 27) { // esc
                    cancel_edit();
                    return;
                }
            };



            // button to add new row
            if ($.bs.can_write_file())
                $(".btn_toc_add").click(function(e) {
                    cmd_add_row();
                });



            // init toc table

            
			var tbl = $(this);


            // init header row
            var row_header = $(this)[0].insertRow(-1);
            $(row_header).addClass('toc_header').addClass('nodrag').addClass('nodrop');
            $(row_header).attr('row_id', -2);

            // menu cell
            $(row_header).append("<th>&nbsp;</th>");

            // columns of the header
            $(toc_columns).each(function(index, column) {
                if (column.type == 'product_submitted_id')
                    return;
                $(row_header).append("<th></th>");
                var cell = $("th:last", row_header);
                //if (typeof(column.width) != 'undefined')
                //    cell.width(column.width);
                cell.addClass('c_' + column.name)
                    .html(column.label);
            });


            // init editor row
            var row_editor = $(this)[0].insertRow(-1);
            $(row_editor).hide();
            $(row_editor).addClass('toc_edit');
            $(row_editor).attr('row_id', -1);
            $(row_editor).attr('row_type', 'editor');

            // menu column
            var cell = row_editor.insertCell(-1);
            $(cell).html("&nbsp;");

            // columns of the editor row
            $(toc_columns).each(function(index, column) {
                if (column.type == 'product_submitted_id')
                    return;
                var cell = row_editor.insertCell(-1);
                $(cell).addClass('c_' + column.name);
                if (column.type == 'items')
                    return;
                $(cell).html(
                    '<input type="text" id="ci_' + column.name + '" name="' + column.name
                    + '" class="toc_edit" value="" style="width:'
                    + 10 + 'px;" />');
                //+ (column.width - 4) + 'px;" />');
                if (column.type == 'product_submitted') {
                    //$('#ci_'+column.name, cell).addClass('toc_product_submitted');
                    $(cell).append('<input type="hidden" class="toc_edit" id="ci_product_submitted_id" name="product_submitted_id" />');
                }
                if ($.bs.can_write_file())
                    $('#ci_' + column.name).keydown(function(event) {
                        defaultKeydownHandler(this, event);
                    });
            });

            if ($.bs.can_write_file())
                $(tbl).tableDnD(row_drag);

            
            var notice = $('#table-action-bar p.autosave-notice');
			notice.html( 'Drawing toc...');
			notice.addClass('notice-wait');
			// Asynchronous row drawing
			var drawing_row_id = 0;
			var drawNextRow = function() {
				if (drawing_row_id >= toc_table.length) {
					notice.removeClass('notice-wait');
					notice.html('');
					return;
				}
				add_row(toc_table[drawing_row_id]);
				drawing_row_id++;
				setTimeout(drawNextRow, 10);
			}

			drawNextRow();

			
            // ajax request wrapper for all toc actions
            $.extend($.fn.toc, {
                ajax: function(data) {
                    var complete = data.success;
                    data.success = function(html) {
                        var notice = $('#table-action-bar p.autosave-notice');
                        if (notice)
                            $(notice).html($.bs.get_template('details_autosaved', {
                                date: $.bs.time()
                            }));
                        complete(html);
                    };
                    var notice = $('#table-action-bar p.autosave-notice');
                    if (notice)
                        $(notice).html($.bs.get_template('details_autosaving'));
                    $.ajax(data);
                }
            });

            // write mode
            if ($.bs.can_write_file()) {
                $(tbl).tableDnDUpdate(row_drag);

                // ?
                $('#ci_product_submitted_id')
                    .bind('beforeEdit', function() {
                        $(this).attr('product_name', $('#ci_product_submitted').val());
                        $(this).attr('manufacturer_name', $('#ci_manufacturer').val());
                    })
                    .bind('afterEdit', function() {
                        if ($('#ci_product_submitted').val()
                            && $(this).attr('product_name') != $('#ci_product_submitted').val())
                           $(this).val('');
                        if ($('#ci_manufacturer').val()
                            && $(this).attr('manufacturer_name') != $('#ci_manufacturer').val())
                            $(this).val('');
                    });

                $('#ci_product_submitted')
                    .bind('beforeEdit', function() {
                        if ("object" == typeof _edit_row) {
                            var id = $(_edit_row).attr('row_id');
                            if (items_count(id) && $('#ci_product_submitted_id').val() && $('#ci_product_submitted_id').val() != "0") {
                                $(this).attr('disabled', 'disabled');
                                $('#ci_manufacturer').attr('disabled', 'disabled');
                            } else {
                                $(this).removeAttr('disabled');
                                $('#ci_manufacturer').removeAttr('disabled');
                            }
                        }
                        $(this).attr('can_autocomplete', "on");
                    })
                    .bind('afterEdit', function() {
                        $(this)
                            .removeAttr('can_autocomplete')
                            .removeAttr('disabled')
                            .trigger('stop');
                        $('#ci_manufacturer').removeAttr('disabled');
                        //var $product_submitted_id = $('#ci_product_submitted_id');
                        //if ($product_submitted_id.attr('product_name') != $(this).val())
                        //    $product_submitted_id.val('');
                        //if ($product_submitted_id.attr('manufacturer_name') != $('#ci_manufacturer').val())
                        //    $product_submitted_id.val('');

                    })
                    .unbind("keydown")
                    .keydown(function(evt) {
                        if ($(this).attr('autocomplete') != 'on') {
                            defaultKeydownHandler(this, evt);
                        }
                    })
                    .autocomplete('/jstoc/product_autocomplete', {
                        minChars: 3,
                        dataType: 'json',
                        matchSubset: false,
                        parse: function(data) {
                            var arr = data.Result;
                            var parsed = [];
                            for (var i = 0; i < arr.length; i++) {
                                parsed[parsed.length] = {
                                    data: arr[i],
                                    value: arr[i].id,
                                    result: unescapeHTML(arr[i].title)
                                };
                            }
                            return parsed;
                        },
                        formatItem: function(data, pos, count, q) {
                            return $.bs.get_template('toc_autocomplete_row', data);
                        },
                        scrollHeight: '180',
                        scroll: true,
                        max: 20
                    })
                    .result(function(evt, data, formatted) {
                        var product_id = data.id;
                        $('#ci_product_submitted_id')
                            .val(product_id)
                            .attr('product_name', $('#ci_product_submitted').val())
                            .attr('manufacturer_name', data.manufacturer);
                        $('#ci_manufacturer')
                            .val(data.manufacturer);

                        // submit row changes, then open product details dialog
                        var $tr = $(this).parents('tr:first');
                        if (0 == submit_edit(
                                function() {
                                    showProductDetails(product_id, $tr);
                                }
                            )
                        ) {
                            showProductDetails(product_id, $tr);
                        }

                    });

                $('input.table-action-save').click(function() {
                    submit_edit();
                });

                $('.table-action-attach')
                .click(function() {
                    cancel_edit();
                    $.bs.attach_dialog(
                        { package_id: item.id },
                        function(package_id, id, endCallback) {
                            add_new_item(null, id, 'file', endCallback);
                        },
                        function(package_id, id, endCallback) {
                            remove_item(null, id, 'file', endCallback)
                        },
                        function(data) {
                            window.location.reload();
                        }
                    );
                })
                .trigger('binded_click');

                // if there is no rows in the toc table at all
                // then add one row and open it in edit mode            
                if (0 == $(toc_table).size())
                    cmd_add_row();
            }

        }
    });


    $(document).ready(function() {
		new $('#toc').toc();               // init toc table

        $('#package-details .half').each(function() {
            $(this).find('input').width($(this).width() - ($.browser.msie ? 150 : 130));
        });
    });


})(jQuery);
