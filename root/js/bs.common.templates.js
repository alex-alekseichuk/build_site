(function($) {

    $.bs.template_add('ajax_error',
        "An error occurred while processing your request.<br />" +
        "The response was:<br />  #{response}"
    );

    $.bs.template_add('notice_undelivered_one',
        'Notice: <a href="/messages/item?id=#{id}">Message failed</a>'
    );

    $.bs.template_add('notice_undelivered_some',
        'Notice: <a href="/messages/list?status=failed&from=me&date=all">#{count} messages failed</a>'
    );

    $.bs.template_add('unfaxable_title',
        'This file format cannot be faxed.'
    );
    // dialog upload and tab_upload of attach dialog
    $.bs.template_add('dialog_upload',
                '<div id="upload-dialog" title="Upload file">' +
                    '<form id="sidebar-upload-form" action="/folders/upload" method="post">' +
                        '<input type="hidden" value="_user" name="pid" />' +
                        '<label>File to upload: </label><br />' +
                        '<input type="file" name="file" />' +
                    '</form>' +
                '</div>'
    );

    // tab_dd of attach dialog
    $.bs.template_add('dialog_dd',
                '<div class="dialog-dd-head">Private Files</div>' +
                '<div class="dialog-dd-section"><table class="attach-dd">#{items_user}</table></div>' +
                '<div class="dialog-dd-head">Location Files</div>' +
                '<div class="dialog-dd-section"><table class="attach-dd">#{items_location}</table></div>' +
                '<div class="dialog-dd-head">Account Files</div>' +
                '<div class="dialog-dd-section"><table class="attach-dd">#{items_account}</table></div>'
    );

    $.bs.template_add('dialog_save',
        '<div id="savepackage-dialog" title="Save package">' +
            '<form action="/jspackage/save" method="post">' +
                '<input type="hidden" name="package_id" id="cpsave_package_id" />' +
            '<table>' +
                '<tr><th><label for="cpsave_title">Name</label></th>'+
                '<td><input type="text" name="cp_title" id="cpsave_title" /></td></tr>' +

                '<tr><th><label for="cpsave_comment">Description</label></th>' +
                '<td><input type="text" name="cp_comment" id="cpsave_comment" /></td></tr>' +

                '<tr><th><label for="cpsave_folder">Folder</label></th>' +
                '<td><select name="cp_folder" id="cpsave_folder" /><p class="loading" style="display:none;">Loading <img alt="" src="/css/images/spinner.gif"/></p></td></tr>' +

            '</table>' +
            '</form>' +
        '</div>'
    );

    $.bs.template_add('selected', ' selected="selected"');
    $.bs.template_add('option', '<option value="#{id}"#{selected}>#{title}</option>');

    $.bs.template_add('progress',
        '<p id="#{id}" class="loading">Loading <img alt="" src="/css/images/spinner.gif"/></p>'
    );

    // attach dialog
    $.bs.template_add('document_drawer_dialog', '<div id="document-drawer-dialog" title="Attach Files to the Package" />' );
    $.bs.template_add('document_drawer_dialog_items', '<div id="output_area" style="width:auto;height:auto;">' +
        '<ul class="ui-tabs-nav"><li class="ui-tabs-nav-item"><a href="#tab_upload">Upload New</a></li><li class="ui-tabs-nav-item"><a href="#tab_dd">Packages and Files</a></li></ul><br style="clear:both;" />' +
        '<div class="dialog-area" style="height: 290px; width: 430px; overflow: auto;"><div id="tab_upload">#{tab_upload}</div><div id="tab_dd">#{tab_dd}</div></div>' + 
        '</div>'
    );
    // items of tab_dd of attach dialog
    $.bs.template_add('document_drawer_item_folder', '<tr><td style="padding-left: #{padding}px"><label class="document_drawer_folder">#{title}</label></td><td>&nbsp</td></tr>' );
    $.bs.template_add('document_drawer_item_file', '<tr><td style="padding-left: #{padding}px"><label class="document_drawer_#{object_type}" for="dd_#{id}">#{title}</label></td><td style="text-align: right;"><input id="dd_#{id}" type="checkbox" name="#{id}" class="groupChk" object_type="#{object_type}" object_id="#{object_id}" #{checked} /></td></tr>' );

    $.bs.template_add('dialog_destructive', '<div id="package-destructive-dialog" title="Current package is unsaved"></div>');
    $.bs.template_add('dialog_destructive_html', '<p>Current package is not saved and will be lost unless you save it now.</p>');

    $.bs.template_add('dialog_confirm', '<div style="display: none" id="confirm-dialog" title="#{title}"></div>');
    $.bs.template_add('dialog_confirm_html', '<p>#{text}</p>');

    $.bs.template_add('add_package_dialog', '<div id="add-package-dialog" title="Adding a package" />' );
    $.bs.template_add('add_package_dialog_html',
        '<div class="output_area" style="padding-right:20px;"><table class="basic"><tr><th class="col-ico"></th><th>Title</th><th>Size</th><th>Pg</th></tr>#{items}</table></div>'
    );

    $.bs.template_add('spinner_dialog', '<div id="spinner-dialog" />' );

})(jQuery);
