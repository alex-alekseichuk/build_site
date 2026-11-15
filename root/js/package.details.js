;(function($) {
    
    // structure describes row grag
    var row_drag = {
        dragHandle: "dragHandle",
        onDragClass: "dragItemRow",
        onDrop: function(table, row) {
            var params = {package_id: item.id};
            $('tr.item_row', '#tbl_items').each(function(e1, e2) {
                params[$(e2).attr('item_id')] = e1 + 1;
            });
            $('td:first', row).removeClass('screw_img').addClass('ajax');
            jQuery.ajax({
                type:       'post',
                url:        '/jspackage/set_items_order',
                data:       params,
                dataType:   'json',
                success:    function(data) {
                    $('td:first', row).removeClass('ajax').addClass('screw_img');
                },
                error:      function(object, cause) {
                    $('td:first', row).removeClass('ajax').addClass('screw_img');
                }
            });

        }
    };

    var tbl = null; // jquery ref. to the table of basic package items

    // internal method to add the row to existing table    
    var _add_item = function(item)
    {
        var s = '<tr item_id="'+item.package_item_id+'" object_id="'+item.id+'" class="item_row">'
            + '<td class="dragHandle ' + ($.bs.can_write_file() ? 'item_ico ' : 'item_ico_ro ') + 'item_img"></td>'
            + '<td><a target="_blank" href="'+item.url+'" target="_blank">'+item.title+'</a></td>'
            + '<td>'+item.size+'</td>'
            + '<td>'+item.page_count+'</td>'
            + ($.bs.can_write_file()
                ? '<td><a href="#" onclick="$.PACKAGE.remove_item(\''+item.id+'\', null); return false;">Delete</a></td>'
                : '')
        if (! isCurrentPackage)
            s += '<td><input type="checkbox" name="chkItem" class="'+item.type+' groupChk" value="'+item.id+'" /></td>'
        s += '</tr>\n';
        tbl.append(s);
    }
    
    // add the table
    var _add_table = function()
    {
        $('#no_items').remove();
        $('#tbl_items').remove();

        var s = '<table id="tbl_items" class="basic"><tr class="nodrag nodrop"><th class="col-ico"></th><th>Title</th><th>Size</th><th>Pg</th>';
        if ($.bs.can_write_file())
            s += '<th>Delete</th>'
        if (! isCurrentPackage)
            s += '<th class="col-pkg-chk">Pkg+</th>'
        s += '</tr></table>';
        $('#table-action-bar').after(s);
        tbl = $('#tbl_items');
        
        // add ability to drag_drop the rows
        if ($.bs.can_write_file())
            tbl.tableDnD(row_drag);
    }
    var _remove_table = function()
    {
        $('#no_items').remove();
        $('#tbl_items').remove();

        tbl = null;
        $('#table-action-bar').after('<p id="no_items">Package is empty.</p>');
    }


    // internal implementation of visual item adding (after real adding by ajax call)
    var add_new_item = function(_package, callback) {
        // add table if it doesn't exist
        if (tbl == null)
            _add_table();

        var files_add = [];
            
        // it can add several items the same time
        for (var i = $('tr', tbl).size()-1; i < _package.items.length; ++i)
        {
            // prepare the data of the item for the row
            var package_item_id = _package.items[i].id;
            var id = _package.items[i].object_id;
            var type = _package.items[i].is_file ? 'file' : 'document';
            var title = _package.items[i].title;
            var url = _package.items[i].url;
            var size = _package.items[i].filesize;
            size = size ? parseInt(size / 1024) : '';
            var page_count = _package.items[i].pages;
            page_count = page_count ? page_count : '';
            
            // really add the row to the table
            _add_item({
                package_item_id: package_item_id
                ,id: id
                ,type: type
                ,title: title
                ,url: url
                ,size: size
                ,page_count: page_count
            });

            if (type == 'file')
                files_add.push(id);
        }

        // update drag-dropping for the table
        if ($.bs.can_write_file())
            tbl.tableDnDUpdate( row_drag );

        if (typeof callback == 'function')
            callback(files_add);
    }


    // add $.package namespace
    $.extend($, {
        PACKAGE: function() {
        }
    });

    // public methods to add and remove items
    // actually, for now we need only one public method remove_item outside
    // another one add_item used internally
    $.extend($.PACKAGE, {
        remove_item: function(id, endCallback) {
            var row = $('tr.item_row[object_id=' + id + ']');
            var $td = $('td:first', row);
            $td.removeClass('screw_img').addClass('ajax');
            $.ajax({
                url: '/jspackage/remove_item',
                type: 'get',
                data: {package_id: package_id, file_id: id},
                dataType: 'json',
                success: function(data) {
                    $td.removeClass('ajax').addClass('screw_img');

                    $('tr.item_row[object_id=' + id + ']').remove();
                    if ($('tr.item_row').size() == 0)
                        _remove_table();
                    else
                        tbl.tableDnDUpdate( row_drag );
                    
                    if (typeof endCallback == "function")
                        endCallback();
                },
                error: function(object, cause) {
                    $td.removeClass('ajax').addClass('screw_img');
                }
            });
        }
        ,add_item: function(id, endCallback) {
            $.ajax({
                url: '/jspackage/add_item',
                type: 'get',
                data: {package_id: package_id, file_id: id},
                dataType: 'json',
                success: function(data) {

                    add_new_item(data.Result['package'], endCallback);
                },
                error: function(object, cause) {
                }
            });
        }
    });

	$(document).ready(function() {
	    
	    // init the table or put the message like: no items
        var n = init_package_items.length;
        if (n > 0)
        {
            _add_table();
            for (var i = 0; i < n; ++i)
                _add_item(init_package_items[i]);
            if ($.bs.can_write_file())                
                tbl.tableDnDUpdate( row_drag );
        } else {
            _remove_table();
        }

        if ($.bs.can_write_file()) {
            // attach-dialog popups by attach button
            $('.table-action-attach')
                .click(function() {
                    $.bs.attach_dialog(
                        {package_id: item.id},
                        function(package_id, id, endCallback) {
                            $.PACKAGE.add_item(id, endCallback);
                        },
                        function(package_id, id, endCallback) {
                            $.PACKAGE.remove_item(id, endCallback);
                        },
                        function(data) {
                            window.location.reload();
                        }
                    );
                })
                .trigger('binded_click');
        } else {
            $('.table-action-attach').attr('disabled', 'disabled');
            $('.table-action-clear').attr('disabled', 'disabled');
        }
    });

})(jQuery);
