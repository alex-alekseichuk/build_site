/**
 *
 */

String.prototype.startsWith = function(str) {
    return (this.indexOf(str) === 0);
}

if(jQuery) (function($){
    $.extend($.fn,{

        /**
        *   Resize dialog buttons to equal width
        *   @param {jQuery object}
        *   @return {jQuery object}
        */
        align_dialog_buttons: function() {
            var minBtnWidth = 0;
            var btns = $(this).parents('div.ui-dialog').find('button');
            btns
                .each( function() { if ($(this).width() > minBtnWidth) minBtnWidth = $(this).width(); } )
                .width(minBtnWidth + 10);
            return $(this);
        },


        /**
        *   Display a spinner instead of dialog buttons (when an action have been started)
        *   @param {jQuery object}
        *   @return {jQuery object}
        */
        spinner_dialog: function() {
            $(this).parents('.ui-dialog').find('.ui-dialog-buttonpane').addClass('ajax-dlg');
            return $(this);
        },


        /**
        *   Remove spinner and get back dialog buttons
        *   @param {jQuery object}
        *   @return {jQuery object}
        */
        clear_spinner: function() {
            $(this).parents('.ui-dialog').find('.ui-dialog-buttonpane').removeClass('ajax-dlg');
            var id = $(this).attr('id');
            var sel = $('#' + id + '-spinner');
            if (sel.length) {
                sel.remove();
                $(this).show();
            }

            return $(this);
        },

        spinner_button: function() {
            var $btn = $(this);
            var id = $btn.attr('id');
            var span = $('<span id="' + id + '-spinner" />');
            var pad  = Math.round(($btn.width() - 16) / 2) + 9;
                span
                    .css({display: 'inline', padding: '8px ' + pad + 'px'})
                    .html('<img src="/css/images/spinner.gif" alt="" />');
                $btn.before(span);
                $btn.hide();
            return $btn;
        },
        
        /**
        *   Add a handler to submit the dialog if ENTER key was pressed
        *   @param {jQuery object}
        *   @return {jQuery object}
        */
        handle_dialog_keys: function() {
            $ok = $(this).parents('.ui-dialog').find('.ui-dialog-buttonpane button:first');
            $(this).find(':input').keypress(function(evt) {
                if (evt.keyCode == 13)
                    $ok.click();
            });
            return $(this);
        },


        /**
        *   Resize the dialog to display properly specified inner elements
        *   @param {jQuery object} this   the dialog
        *   @param {String} selector        jQuery-like item selector (or false)
        *   @param {int} minWidth           minimal width of dialog
        *   @return {jQuery object} 
        */
        stretch_dialog: function(selector, minWidth) {
            if (selector) {
                var _minWidth = $(this).find(selector).width();
                if (minWidth < _minWidth)
                    minWidth = _minWidth;
            }

            $(this).find(':input').width(minWidth - 4);
            $(this).find('p').width(minWidth - 4);
            minWidth += 110;

            if ($(this).parents('div.ui-dialog').width() < minWidth)
                $(this).parents('div.ui-dialog').width( minWidth );
            return $(this);
        },
        

        /**
        *   Show the dialog with some pre-defined setting and aligned buttons, handled 
        *   ENTER-press event without spinner
        *   @param {jQuery object} this      the dialog
        *   @param {params} params           dialog parameters 
                                             (the same as in native $.dialog method)
        *   @return {jQuery object} 
        *   
        *   This is a wrapper around the $.dialog method. Call it instead of $.dialog to 
        *   display dialogs with unified style and behaviour.
        */
        bs_dialog: function(options) {
            var $this = $(this);

            if (typeof options.modal == "undefined")
                options.modal = true;
            if (typeof options.bgiframe == "undefined")
                options.bgiframe = true;

            if (typeof options.overlay == "undefined")
                options.overlay_bgiframe = false;
            options.overlay = {
                opacity: 0.5,
                background: "gray"
            };

            $this.clear_spinner();

            $this.dialog(options);
            if (options['autoOpen'] != 'false')
            {
                $this.align_dialog_buttons();
                $this.handle_dialog_keys();
            }

            return $this;
        },
        bs_dialog_open: function() {
            var $this = $(this);

            $this.dialog('open');
            $this.align_dialog_buttons();
            $this.handle_dialog_keys();

            return $this;
        },

        /**
        *   Fill a select input with the list of accessible folders
        *   @param {jQuery object}  this     the input
        *   @param {string} parent_id        id of folder which should be selected
        *   @param {boolean} force_reload    flag to reload a list every time when
        *                                    function is called
        *   @return {jQuery object}
        *
        *   By default it fills the select only when it doesn't contain any items.
        *   Use force_reload flag to re-fill the input.
        */
        load_user_folders: function(parent_id, force_reload, checkAbilityToMove) {
            var $this = $(this);

            var enable_ok_button = function() {
                var $ok = $this.parents('div.ui-dialog:first').find('.ui-dialog-buttonpane button:first');
                $ok.attr('disabled', false).removeClass('disabled');
            };

            if ($this.find("option").length && !force_reload) {
                enable_ok_button();
                return $this;
            }

            $this.parent().find('.loading').show();
            $this.hide();

            $.bs.get_user_folders(function(items) {
                var optionsStr = '';
                var current_title;
                $.each( items, function() {

                    optionsStr += $.bs.get_template('option', {
                        id: this.id,
                        title: this.path,
                        selected: parent_id == this.id ? $.bs.get_template('selected') : ''
                    });
                    if (parent_id == this.id)
                        current_title = this.path;
                });
            
                $this.parent().find('.loading').hide();

                $this
                    .html(optionsStr)
                    .show();
                if (typeof checkAbilityToMove == 'function')
                    checkAbilityToMove(current_title);

                enable_ok_button();
            });
            return $this;
        },
        focus_safe: function() {
            try {
                this.focus();
            } catch(er) {}
            return this;
        }
    })
})(jQuery);


if(jQuery) (function($){
    $.extend($,{
        bs: function() {
        }
    })
})(jQuery);


if (jQuery) (function($) {
    $.extend($.bs, {
        templates: {},
        currentPackageJSON: {},
        __user_folders: false,


        /**
        *   Add a template to the template set
        *   @param {String} template_id      short name to access the template from
        *                                    the other functions
        *   @param {String} template         template code (#{variable} directives 
        *                                    are allowed)
        *   @return null
        *
        *   See also /js/jquery.template.js
        */
        template_add: function(template_id, template) {
            $(jQuery.bs.templates).attr(template_id, template);
        },


        /**
        *   Parse a template from the template set and get the HTML-code
        *   @param {String} template_id      name of the template
        *   @param {Object} values           template variable values
        *   @return {String}
        *
        *   Template should be added to the set with $.bs.add_template() previously.
        *   See also /js/jquery.template.js
        */
        get_template: function(template_id, values) {
            var obj = jQuery(jQuery.bs.templates).attr(template_id);
            var returnValue = '';

            if (obj != null) {
                returnValue = jQuery.tmpl(obj, values);
            }

            return returnValue;
        },


        /**
        *   Returns the size of an item
        *   @param {object} item   the dialog
        *   @return {String} 
        */
        get_size: function(item) {
            return ((item.page_count > 0 || typeof (item.file_size) != 'undefined')
						?
						    " ("
						    + (item.page_count > 0 ? item.page_count + " pg" : "")
						    + (item.page_count > 0 && typeof (item.file_size) != 'undefined' ? ", " : "")
						    + (typeof (item.file_size) != 'undefined' ? item.file_size + " kB" : "")
						    + ")"
						: "");
        },


        /**
        *   Returns a link to an item
        *   @param {object} item   the dialog
        *   @return {String} 
        */
        get_link: function(item) {
            var id = typeof item.object_id == "undefined" ? item.id : item.object_id;

            if (typeof item.download_url != "undefined")
                return item.download_url;

            if (typeof item.url != "undefined")
                return item.url;

            if (item.is_file || (typeof item.type != "undefined" && item.type == "file"))
                return '/folders/download?file_id=' + (item.file_id ? item.file_id : id);

            return '';
        },


        confirm: function(title, text, okCallback) {
            var dlg = jQuery('#confirm-dialog');
            if (dlg.length == 0) {
                jQuery(document.body).after($.bs.get_template('dialog_confirm', { title: title }));
                dlg = jQuery('#confirm-dialog');
            }

            var dialogClose = function() { dlg.dialog('close'); };

            dlg
						.html($.bs.get_template('dialog_confirm_html', { text: text }))
						.show()
						.bs_dialog({
						    buttons: {
						        "Yes": function() {
						            dlg.spinner_dialog();
						            if ("function" == typeof okCallback)
						                okCallback(dialogClose);
						        },
						        'No': function() {
						            dialogClose();
						        }
						    }
						});
        },

        /**
        *   Display a fax delivery failure notice
        *   @param {Object} obj              destructive element (e.g. link or submit button)
        *   @param {Object} callback         a code to execute after the package was saved
        *   @return {String}
        *
        */
        notify_undelivered_messages: function(ar) {
            var $notice = $('#notice-undelivered');
            if (ar.length == 0)
                return $notice.hide();

            var template = ar.length == 1 ? 'notice_undelivered_one' : 'notice_undelivered_some';
            var html = $.bs.get_template(template, {
                id: ar[0],
                count: ar.length
            });
            $notice.html(html);
            $notice.fadeIn();
        },



        /**
        *   Display an alert to prevent losing the current package
        *   @param {Object} obj              destructive element (e.g. link or submit button)
        *   @param {Object} callback         a code to execute after the package was saved
        *   @return {String}
        *
        */
        package_destructive_dialog: function(obj, callback) {
            var dlg = jQuery('#package-descructive-dialog');
            if (dlg.length == 0) {
                jQuery(document.body).append($.bs.get_template('dialog_destructive'));
                dlg = jQuery('#package-destructive-dialog');
                dlg.bs_dialog({ autoOpen: false });
            }

            var dialogClose = function() { dlg.dialog('close'); };

            var doAction = callback;

            if (typeof doAction != "function") {
                var tn = obj.tagName.toLowerCase();
                var $obj = $(obj);

                switch (tn) {
                    case 'a':
                        var url = $obj.attr('href');
                        doAction = function() {
                            if (url)
                                document.location = url;
                        };
                        break;

                    case 'input':
                        var p = $obj.parents('form');
                        doAction = function() {
                            var inp = $('<input type="hidden" />');
                            inp
                                    .attr('name', $obj.attr('name'))
                                    .val($obj.attr('value'));

                            p.append(inp);
                            p.submit();
                        }
                        break;
                }
            }

            dlg
                       .html($.bs.get_template('dialog_destructive_html'))
                       .dialog('option', 'buttons', {
                           "Save Package": function() {
                               $.bs.save_package(false, function() {
                                   dialogClose();
                                   doAction();
                               }, dialogClose);
                           },
                           'Don\'t save': function() {
                               doAction();
                               dialogClose();
                           }
                       }
                       )
                       .bs_dialog_open();

        },

        /**
        *   Display a dialog to upload new file or select some Document Drawer files
        *   This dialog is opened for attach button on package details page (basic pr with toc) and via context menu of CPSB
        *
        */
        attach_dialog: function(upload_data, dd_callback_add, dd_callback_remove, upload_callback) {

            // save id of this package
            // it's not current package all the time                    
            var package_id = upload_data.package_id;

            // init upload tab data
            if (typeof upload_data == "object")
                upload_data.ajax = 1;
            else
                upload_data = (typeof upload_data != "undefined" && upload_data.length) ? upload_data + "&ajax=1" : "?ajax=1";

            // function to fill one of 3 sections (Private, Location, Account) with set of folder items with checkboxes
            var processing_data = function(items, parentId, level) {
                var resultStr = "";
                $.each(items, function() {
                    if (this.parent == parentId) {
                        if (this.type == 'folder') {
                            resultStr += $.bs.get_template('document_drawer_item_folder', { padding: 20 * level, title: this.title });
                            resultStr += processing_data(items, this.id, level + 1);
                        } else {
                            var isThisPackage = package_id == this.id && this.type == 'archive';
                            var checked = this.added || isThisPackage ? 'checked="checked"' : '';
                            if (isThisPackage)
                                checked += ' disabled="disabled"'
                            resultStr += $.bs.get_template('document_drawer_item_file',
                                        {
                                            padding: 20 * level, title: this.title, id: this.id, object_type: this.type, object_id: this.id, checked: checked
                                        });
                        }
                    }
                });
                return resultStr;
            }

            var spinnerDlg = $('#spinner-dialog');
            if (spinnerDlg.length == 0) {
                $(document.body).append($.bs.get_template('spinner_dialog'));
                spinnerDlg = $('#spinner-dialog');
                spinnerDlg
                            .html('<img src="/css/images/spinner.gif" alt="" />')
                            .dialog({
                                title: 'Loading Packages & Files',
                                width: 450,
                                height: 80,
                                bgiframe: true
                            });
            } else {
                spinnerDlg
                            .html('<img src="/css/images/spinner.gif" alt="" />')
                            .dialog('open');
            }



            // get data (list of file objects) for DD tab
            $.getJSON('/folders/get?package_id=' + package_id + "&q=" + Math.random(), function(data) {
                spinnerDlg.dialog('close');

                var html = $.bs.get_template('document_drawer_dialog_items', {
                    tab_dd: $.bs.get_template('dialog_dd', {
                        items_user: processing_data(data.Result.items_user, null, 0),
                        items_location: processing_data(data.Result.items_location, null, 0),
                        items_account: processing_data(data.Result.items_account, null, 0)
                    }),
                    tab_upload: $.bs.get_template('dialog_upload')
                });

                // create the panel (div) for the dialog if it's not done yet
                var documentDrawerDlg = $('#document-drawer-dialog');

                // special method to resize internal tabs after whole dialog resize
                var resize_dialog_area = function() {
                    var $output_area = $('#output_area', documentDrawerDlg);
                    var $area = $('.dialog-area', documentDrawerDlg);
                    var c = documentDrawerDlg.parents('div.ui-dialog:first');
                    $area
                                .width(c.width() - 20)
                                .height(c.height() - 110);
                }

                if (documentDrawerDlg.length == 0) {
                    $(document.body).append($.bs.get_template('document_drawer_dialog'));
                    documentDrawerDlg = $('#document-drawer-dialog');

                    // open the dialog
                    documentDrawerDlg
                                .bs_dialog({
                                    autoOpen: true,
                                    width: 550,
                                    height: 430,
                                    minWidth: 370,
                                    minHeight: 400,
                                    open: function(event, ui) {
                                        resize_dialog_area();
                                    },
                                    close: function() {
                                        if ($.bs.addPackageDlg != null) {
                                            $.bs.addPackageDlg.dialog('close');
                                            $.bs.addPackageDlg = null;
                                        }
                                    },
                                    resizeStop: function(event, ui) {
                                        resize_dialog_area();
                                    }
                                });
                }
                documentDrawerDlg
                            .html(html)

                            .dialog('option', 'buttons', {
                                "Ok": function() {
                                    var $this = $(this);
                                    if ($('#tab_dd').is(':visible')) {
                                        $(this).dialog('close');
                                    } else { // upload
                                        $this.spinner_dialog();
                                        jQuery("#sidebar-upload-form").ajaxSubmit({
                                            data: upload_data,
                                            success: function(responseText) {
                                                var upload_data = eval('(' + responseText + ')');
                                                if (typeof upload_data.error != 'undefined') {
                                                    $this.clear_spinner();
                                                    UploadError(upload_data.error);
                                                } else {
                                                    if (typeof upload_callback == "function") {
                                                        upload_callback(upload_data, function() {
                                                            $this.dialog('close');
                                                        });
                                                    }

                                                }
                                            },
                                            error: function(xhr, textStatus, errorThrown) {
                                                $this.clear_spinner();
                                                if (textStatus == 'timeout')
                                                    UploadError('Request timed-out. Please try again.');
                                                else
                                                    UploadError(textStatus);
                                            },
                                            //dataType: 'json',
                                            type: 'post',
                                            resetForm: true
                                        });
                                    }

                                },
                                'Cancel': function() {
                                    $(this).dialog('close');

                                }
                            })

                            .bs_dialog_open();
                resize_dialog_area();

                // set handler for the checkboxes                        
                $(".groupChk", documentDrawerDlg).each(function() {
                    var $this = $(this);
                    var $parent = $this.parent();

                    $this.click(function() {

                        if ($this.is(':checked')) {

                            // code to really add checked file or package
                            var adding = function() {

                                $parent.addClass('ajax');

                                // do adding
                                dd_callback_add(
                                            package_id
                                            , $this.attr('object_id')
                                            , function(files_add) {
                                                $parent.removeClass('ajax');
                                                if (typeof files_add != 'undefined')
                                                    $(".groupChk", documentDrawerDlg).each(function() {
                                                        var $this = $(this);

                                                        for (var i = 0; i < files_add.length; ++i)
                                                            if (files_add[i] == $this.attr('object_id'))
                                                            $this.attr('checked', 'checked');
                                                    });
                                            }
                                        );

                                // disable checkbox of package
                                if ('archive' == $this.attr('object_type'))
                                    $this.attr('disabled', 'disabled');
                            };

                            // is it a package?
                            if ('archive' == $this.attr('object_type')) {
                                // we need confirmation first for the package
                                $this.attr('checked', false);
                                $.bs.add_package_dialog($this.attr('object_id'), package_id, function() { $this.attr('checked', 'checked'); adding(); });
                            } else {
                                // it's file, so, just add it
                                adding();
                            }

                        } else {

                            if ('file' == $this.attr('object_type'))
                                dd_callback_remove(
                                            package_id
                                            , $this.attr('object_id')
                                            , function() { $parent.removeClass('ajax'); }
                                        );
                        }
                    });
                });

                var UploadError = function(error_message) {
                    alert("Upload error: " + error_message);
                }

                // init tabs: upload, dd
                $('#output_area', '#document-drawer-dialog').tabs(
                            { selected: 0, // first tab is selected by default
                                select: function(event, ui) {
                                    // show/hide second Cancel button for specified tab
                                    var $btnCancel = $('button', $('div.ui-dialog-buttonpane', $('#document-drawer-dialog').parents('div.ui-dialog:first')))[1];
                                    if (ui.index == 1)
                                        $($btnCancel).hide();
                                    else
                                        $($btnCancel).show();
                                }
                            }
                        );

            });
        },


        /**
        *   Get current time in "03:12 am" format
        *   @return {String}
        */
        time: function() {
            var dt = new Date;
            var h = dt.getHours() % 12;
            var m = dt.getMinutes();

            h = h < 10 ? (h == 0 ? 12 : '0' + h) : h;
            m = m < 10 ? '0' + m : m;

            var str = h + ':' + m + ' ' + (dt.getHours() < 12 ? 'am' : 'pm');
            return str;
        },

        /**
        *   Show an application error
        *   @param {String} errorText      error message
        *   @param {String} context        context (e.g. CPS for Current Package Sidebar etc)
        *   @param {function} callback     a function to call after closing the alert
        *   @return null
        *
        *   You can add handlers for different contexts. 
        *   Modal dialog with the error message is shown by default.
        */
        displayErrorMessage: function(errorText, context, callback) {
            var divErrorWindow = jQuery('#error-dialog');
            if (divErrorWindow.length == 0) {
                jQuery(document.body).after('<div id="error-dialog"><p/></div>');
                divErrorWindow = jQuery('#error-dialog');
            }
            // if ( context == 'CPS' ) {
            // Dialog is default now for all context types
            divErrorWindow.find('p').html(errorText);
            divErrorWindow.bs_dialog({
                title: 'Error',
                buttons: {
                    "Close": function() {
                        $(this).dialog("close");
                        if (typeof callback == "function")
                            callback();
                    }
                }
            });
            //}
        },


        /**
        *   Set/get a package data
        *   @param {Object} value            package JSON (optional)
        *   @return {Object}
        */
        current_package: function(value) {
            if (value != undefined) {
                this.currentPackageJSON = jQuery.extend({}, value);
            }
            return this.currentPackageJSON;
        },


        /**
        *   Check if the current package can be lost
        *   @return {boolean}
        */
        should_save_package: function() {
            var pkg = $.bs.current_package();
            if (!pkg || !pkg['package'])
                return false;

            if (pkg['package'].is_saved || typeof pkg['package'].items == "undefined" || pkg['package'].items.length == 0)
                return false;

            return true;
        },

        /**
        *   Load a list of accessible folders and do some action with it
        *   @param {function} callback        a function to call after folders list is loaded
        *   @return null
        *
        *   Callback function gets an array of items. Each item containing 
        *   'id' and 'title' fields.
        */
        get_user_folders: function(callback) {
            if ($.bs.__user_folders)
                if (typeof callback == "function")
                callback($.bs.__user_folders);

            jQuery.getJSON('/jspackage/folders',
                function(data) {
                    $.bs.__user_folders = data.Result.items;
                    if (typeof callback == "function")
                        callback($.bs.__user_folders);
                }
            );
        },


        /**
        *   Show a dialog with package some details to save it
        *   @param {String} package_id
        *   @param {function} okCallback      a function to call after save request was sent
        *   @param {function} cancelCallback  a function to call after closing the dialog
        *   @return null
        *
        *   okCallback function gets a JSON containing package details
        */
        save_package: function(package_id, okCallback, cancelCallback) {

            var savePackageDlg = jQuery('#savepackage-dialog');
            if (savePackageDlg.length == 0) {
                $(document.body).append($.bs.get_template('dialog_save'));
                savePackageDlg = jQuery('#savepackage-dialog');
                savePackageDlg.bs_dialog({
                    width: 300
                    , height: 150
                    , minWidth: 300
                    , minHeight: 150
                    , autoOpen: false
                });
            }

            var pkg = $.bs.current_package();
            var $this = $(this);
            if (pkg && pkg['package'] && (!package_id || pkg['package'].id == package_id)) {
                if (pkg['package']) {
                    $this.find('#cpsave_title').val(pkg['package'].title);
                    $this.find('#cpsave_comment').val(pkg['package'].description);

                    if (!package_id)
                        package_id = pkg['package'].id;
                }
            }

            $this.find('#cpsave_package_id').val(package_id);


            var closeDialog = function() {
                savePackageDlg.dialog('close');
            };

            var buttons = {
                'Ok': function() {
                    savePackageDlg.spinner_dialog();
                    var $form = $(savePackageDlg.find('form'));
                    var data = $form.serialize();

                    $.ajax({
                        url: $form.attr('action'),
                        type: $form.attr('method'),
                        data: data,
                        dataType: 'json',
                        success: function(data) {
                            closeDialog();
                            if (typeof okCallback == "function")
                                okCallback(data);
                        }
                    });
                },
                'Cancel': function() {
                    savePackageDlg.find('.loading').hide();
                    closeDialog();
                    if (typeof cancelCallback == "function")
                        cancelCallback();
                }
            }

            savePackageDlg
                .stretch_dialog('#cpsave_folder', 180)
                .dialog('option', 'buttons', buttons)
                .bs_dialog_open()
                ;

            // disable Ok button till folders list will be ready
            var $ok = $(savePackageDlg).parents('div.ui-dialog:first').find('.ui-dialog-buttonpane button:first');
            $ok.attr('disabled', 'disabled').addClass('disabled');

            // load list of folders or use already loaded; enable Ok button when it would be ok
            var parent_id = $.bs.current_package() && $.bs.current_package()['package'] && $.bs.current_package()['package'].pid ? $.bs.current_package()['package'].pid : '';
            savePackageDlg.find('#cpsave_folder').load_user_folders(parent_id);

        },


        /**
        *   Put some message to notice area. It's under breadcrumbs.
        *   @param {String} message
        *   @return null
        */
        notice: function(message) {
            var notice = $('p.notice')[0];
            if (!notice) {
                var main_block = $('div.b-block');
                if (!main_block) {
                    alert(message);
                    return;
                }
                $(main_block).prepend('<p class="notice">' + message + '</p>');
                return;
            }
            $(notice).html(message);
        },


        /**
        *   If there is parameter coming then save it to use later.
        *   In other case it just returns previously saved value
        */
        _can_write_file: false,
        can_write_file: function(can_write) {
            if (typeof can_write !== 'undefined')
                $.bs._can_write_file = can_write;
            return $.bs._can_write_file;
        },

        search_term: function(term) {
            var $form = $('form#search');
            $('#term_' + term, $form).attr('checked', 'checked');
            $form.submit();
        },

        // show confirmation dialog for add package to package
        // and call callback if OK clicked
        add_package_dialog: function(source_id, target_id, callbackOk, callbackCancel) {

            if ($.bs.addPackageDlg != null) {
                $.bs.addPackageDlg.dialog('close');
                $.bs.addPackageDlg = null;
            }

            var spinnerDlg = $('#spinner-dialog');
            if (spinnerDlg.length == 0) {
                $(document.body).after($.bs.get_template('spinner_dialog'));
                spinnerDlg = $('#spinner-dialog');

                // open the dialog in preview (loader) mode with spinner
                spinnerDlg.html('<img src="/css/images/spinner.gif" alt="" />')
                    .dialog({
                        title: 'Loading Package',
                        width: 450,
                        height: 80,
                        bgiframe: true
                    });
            } else {
                spinnerDlg.dialog('open');
            }

            $.getJSON(
                '/jspackage/add_package_items?source_id=' + source_id + '&target_id=' + target_id + '&q=' + Math.random()
                , function(data) {
                    spinnerDlg.dialog('close');

                    if (typeof data.Result.error != 'undefined') {
                        $.bs.displayErrorMessage("Can't load package", 'ajax');
                        return;
                    }

                    var items = '';
                    for (var i in data.Result.items)
                        items += '<tr><td class="ico_file"></td><td><a target="_blank" href="' + data.Result.items[i].download_url + '">' + data.Result.items[i].title + '</td><td>' + data.Result.items[i].filesize_kb + '</td><td>' + data.Result.items[i].page_count + '</td></tr>\n';
                    var package_items = $.bs.get_template('add_package_dialog_html', { items: items });

                    $.bs.addPackageDlg = $('#add-package-dialog');
                    if ($.bs.addPackageDlg.length == 0) {
                        $(document.body).after($.bs.get_template('add_package_dialog'));
                        $.bs.addPackageDlg = $('#add-package-dialog');

                        // open the dialog in preview (loader) mode with spinner
                        $.bs.addPackageDlg.html(package_items)
                            .bs_dialog({
                                autoOpen: false,
                                width: 450,
                                height: 300,
                                minWidth: 350,
                                minHeight: 200,
                                bgiframe: true
                            });
                    }

                    $.bs.addPackageDlg
                        .dialog('option', 'title', 'Adding a package: ' + data.Result.package_title)
                        .dialog('option', 'buttons', {
                            "Ok": function() {
                                var $this = $(this);
                                $.bs.addPackageDlg = null;
                                $(this).dialog('close');
                                if (typeof callbackOk == 'function')
                                    callbackOk();
                            },
                            'Cancel': function() {
                                var $this = $(this);
                                $.bs.addPackageDlg = null;
                                $(this).dialog('close');
                                if (typeof callbackCancel == 'function')
                                    callbackCancel();

                            }
                        })
                        .html(package_items)
                        .bs_dialog_open();

                }
            );
        },
        get_short_title: function(title, max_length) {
            var a = title.split(' ');
            var n = a.length;
            var s = '';
            for (var i = 0; i < n; ++i)
                if (a[i].length > max_length) {
                a[i] = a[i].substring(0, max_length);
                s += ' ' + a[i] + '...';
                break;
            } else {
                s += ' ' + a[i];
            }
            return s;
        }


    });

    $.ajaxSetup({
        error: function(XMLHttpRequest, textStatus, errorThrown) {
            if (!XMLHttpRequest.status)
                return;
            var text = $.bs.get_template('ajax_error', { response: XMLHttpRequest.responseText });
            $.bs.displayErrorMessage(text, 'ajax');
        }
    });

})(jQuery);

function unescapeHTML(html) {
    var temp = $('<span/>').html(html);
    var result = $(temp).html();
    temp.remove();
    return result.replace('&amp;', '&');
}


(function($) {
    $(document).ready( function() {
        if ( jQuery.browser.msie && jQuery.browser.version == '6.0'  ) {
            $('ul.b-global-nav').children('li').hover( 
                function() {
                    $('select :not(.td-header select)').css('visibility', 'hidden');
                },
                function() {
                    $('select').css('visibility', 'visible');
                }
            );
        }

        $('.destructive').click(function() {
            if ($.bs.should_save_package()) {
                $.bs.package_destructive_dialog(this);
                return false;
            }
        });
        $('a.help').tooltip({showURL: false});
        $('.suppress a.tooltip').parent_tooltip();
        $.bs.notify_undelivered_messages(undeliveredMessages);

        $("#where").change(function(){
            if ($(this).val() == 'green') {
                location.href = "/search/advanced";
            }
        });
        
        // preload several images        
        var _preload_images = [
            '/css/images/spinner.gif'
        ];
        var _img = new Image();
        var _n_images = _preload_images.length;
        for (var i = 0; i < _n_images; ++i) {
            _img.src = _preload_images[i];
        }
        
    });
})(jQuery);
