
if(jQuery) (function($){

    $.bs.template_add('copymove_dialog',
        '<div style="display: none" id="copymove-dialog" title="Copy / Move">' +
            '<form action="/folders/copy" method="post">' +
                '<input type="hidden" name="file_id" id="copymove_file_id" />' +
            '<table id="tbl_copymove">' +
                '<tr><th><label for="copymove_folder">Folder: &nbsp;</label></th>' +
                '<td><select name="parent_id" id="copymove_folder" /></td></tr>' +
            '</table>' +
            '</form>' +
        '</div>'
    );
    $.bs.template_add('copymove_dialog_copy',
        'The item was copied successfully.'
    );
    $.bs.template_add('copymove_dialog_move',
        'The item was moved successfully.'
    );

    $.bs.template_add('details_autosaving', 'Saving . . .');
    $.bs.template_add('details_autosaved', 'Autosaved at #{date}');
    $.bs.template_add('delete_confirmation', 'Are you sure?');

    $(document).ready( function() {

        $('#action-copy').click(function(){
            
            // if we haven't privileges to write then there is not ability to move
            // there is flag-method; it's undefined if we can't write, so, no method to check for move ability
            var checkAbilityToMove = 
                $.bs.can_write_file()
                ?
                function(sFolder) {
                    var btn_move = jQuery('.ui-dialog-buttonpane').find('button:eq(1)');
                    if (
                        (sFolder.startsWith('Private:') && ((! item.is_same_user) || (! item.is_same_location)) )
                        ||
                        (sFolder.startsWith('Location:') && (! item.is_same_location) )
                    ) {
                        // disable Move button
                        if (! btn_move.attr('disabled'))
                            btn_move.attr('disabled', 'disabled').addClass('disabled');
                        if (jQuery('#copymove_message').length == 0)
                            jQuery('#tbl_copymove').after('<p id="copymove_message">Please copy the item or move it to another location.</p>');
                    } else {
                        // enable Move button
                        if (btn_move.attr('disabled'))
                            btn_move.attr('disabled', '').removeClass('disabled');
                        if (jQuery('#copymove_message').length > 0)
                            jQuery('#copymove_message').remove();
                    }
                }
                : undefined;

            var copymoveDlg = jQuery('#copymove-dialog');
            if ( copymoveDlg.length == 0 ) {
                $(document.body).append( $.bs.get_template('copymove_dialog'));
                copymoveDlg = jQuery('#copymove-dialog');
                
                if (checkAbilityToMove)
                    jQuery('select#copymove_folder', copymoveDlg).change(function() {
                        checkAbilityToMove(jQuery('select#copymove_folder option:selected').text());
                    });
                copymoveDlg
                    .bs_dialog({
                        autoOpen: false
                    });
            }

            $(copymoveDlg).find('#copymove_file_id').val(item.id);

            $(copymoveDlg).find('#copymove_folder').load_user_folders(
                item.parent ? item.parent : '_' + item.scope
                , 1
                , checkAbilityToMove);

            var closeDialog = function() { 
                copymoveDlg.dialog('close'); 
            };
            var process = function(action) { 
                copymoveDlg.spinner_dialog();
                
                var $form = $(copymoveDlg.find('form'));
                var data = $form.serialize();

                $.ajax({
                    url: '/folders/copy',
                    type: 'post',
                    data: data + "&ajax=1&action=" + action,
                    dataType: 'json',
                    success: function(data) {
                        closeDialog();
                        if ('move' == action)
                            document.location = document.location + "&msg=moved";
                        else
                            $.bs.notice($.bs.get_template('copymove_dialog_' + action, {destination: data.Result.folder.path}));
                    },
                    error: function(object, cause) {
                        closeDialog();
                        var error = object.responseText;
                        eval("var data = " + error);
                        if (data && data.Result)
                        {
                            error = data.Result.error;
                        }
                        jQuery.bs.displayErrorMessage(error, 'CopyMove');
                    }
                });
            };

            // compose dialog buttons set
            var buttons = {
                'Copy' : function() {
                    process('copy');
                }
            };
            if (checkAbilityToMove)
                buttons['Move'] =
                    function() {
                        process('move');
                    };
            buttons['Cancel'] = function() {
                closeDialog();
                if (typeof cancelCallback == "function")
                    cancelCallback();
            };

            // init the dialog and add buttons
            copymoveDlg
                .stretch_dialog('#cpsave_folder', 180)
                .dialog('option', 'buttons', buttons)
                .bs_dialog_open();

        });

        $('#action-delete').click(function() {
            if (!confirm($.bs.get_template('delete_confirmation')))
                return;
            document.location = '/folders/delete?file_id=' + item.id;
        });

        if ('moved' == msg)
            $.bs.notice($.bs.get_template('copymove_dialog_move', {}));
    });

})(jQuery);
