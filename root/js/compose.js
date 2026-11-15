;(function($) {

$.extend($.bs, {
    _messageLimits: {},

    messageLimits: function(data) {
        if ( data != undefined ) {
            this._messageLimits = data;
        }
        return this._messageLimits;
    },
    
    // flags indicating that there are one or two limits exceeded by attachments
    limit_size_exceeded: false,
    limit_pages_exceeded: false,
    // internal storage for the recipient (to) addresses
    recipients: [],
    // @return 0-has no addresses, 1-has email, 2-has fax, 3-both
    getRecipientTypes: function() {
        var ret = 0;

        for (field in this.recipients) {
            for (var i = 0; i < this.recipients[field].length; i++) {
                if (this.recipients[field][i].type == 'email')
                    ret |= 1;
                else if (this.recipients[field][i].type == 'fax')
                    ret |= 2;
                else {
                    ret |= this.recipients[field][i].address.indexOf('@') != -1 ? 1 : 2;
                }
            }
        }
        return ret;
    },
    // checks is such address (taken from hash) already added to the set
    hasRecipient: function(data) {
        var addr = $.trim(data.address.toLowerCase());
        for (field in this.recipients) {
            for (var i = 0; i < this.recipients[field].length; i++) {
                if ($.trim(this.recipients[field][i].address.toLowerCase()) == addr)
                    return true;
            }
        }
        return false;
    },
    n_contacts_cart: 0
});

$.extend($.fn, {    
    // add one more recipient to the form
    // @param data maybe as pure string. in this case it's just plain address without exact type added by hand
    //             or maybe the hash of the contact already saved in DB
    // @param obj is optional source html control. we clean it.
    // @param skip_draw optional bool flag. default-false. if true then we don't refresh the form. it means we will do it later by hand.
    addRecipient: function(data, obj, skip_draw) {
        if (!obj)
            obj = $(this);
        if ((typeof data).toLowerCase() != 'object') {
            data = {id: 0, address: data, type: '' };
        }

        var id = obj.attr('id');

        if (!$.bs.recipients[id])
          $.bs.recipients[id] = [];

        if (!$.bs.hasRecipient(data)) {
            $.bs.recipients[id][$.bs.recipients[id].length] = data;
            if (! skip_draw) {
                this.drawRecipients();
            }
            if (obj)
                obj.val('');
        }
    },

    contactDialog: function(btn, data_field, data_id, id, name, type, address)
    {
        var $compose = $(this);
        
        // turn the dialog into spinner mode
        var setSpinner = function() {
            $.bs.recipientContactDlg
                .dialog('option', 'title', 'Loading...')
                .html('<img src="/css/images/spinner.gif" alt="" />')
                .bs_dialog_open();
        };
        
        // turn the dialog into data form mode + provide the data
        var setData = function(data) {
            data = data || {};
            data.company_options = '';
            data.new_company = '';
            data.given_name = data.given_name || '';
            data.family_name = data.family_name || '';
            data.work_phone = data.work_phone || '';
            data.fax_phone = data.fax_phone || '';
            data.email_address = data.email_address || '';
            
            for (var i=0; i<data.companies.length; ++i)
                data.company_options += '<option value="' + data.companies[i][0] + '"' + (data.companies[i][0] == data.addressbook_company_id ? ' selected="selected"' : '') + '>' + data.companies[i][1] + '</option>\n';
            var html = $.bs.get_template('recipient_contact_dialog_html', data);
            
            $.bs.recipientContactDlg
                .dialog('option', 'title', 'Addressbook Contact Details')
                .dialog('option', 'buttons', {
                            "Ok" : function() {
                                var $this = $(this);
                                
                                // check for non empty First Name field
                                if (! $.trim($('#rcd_given_name').val()))
                                {
                                    alert('Please, provide First Name');
                                    $('#rcd_given_name').focus();
                                    return;
                                }
                                // check: there should be email or fax
                                if (! ($.trim($('#rcd_email_address').val()) || $.trim($('#rcd_fax_phone').val())))
                                {
                                    alert('Please, Provide Fax or Email Address');
                                    $('#rcd_fax_phone').focus();
                                    return;
                                }

                                $.bs.recipientContactDlg.spinner_dialog();
                                
                                // save the contact and close dialog
                                $.ajax({
                                    url: "/contacts/person/save",
                                    type: 'POST',
                                    dataType: 'json',
                                    data: 
                                        'id=' + id
                                        + '&given_name=' + $('#rcd_given_name').val()
                                        + '&family_name=' + $('#rcd_family_name').val()
                                        + '&work_phone=' + $('#rcd_work_phone').val()
                                        + '&fax_phone=' + $('#rcd_fax_phone').val()
                                        + '&email_address=' + $('#rcd_email_address').val()
                                        + '&new_company=' + $('#rcd_new_company').val()
                                        + '&company=' + $('#rcd_company').val()
                                        ,
                                    success: function(json) {
                                        $.bs.recipientContactDlg.clear_spinner();
                                        var reply = json.Result;
                                        if ('error' == reply.result)
                                        {
                                            reply.error = reply.error || 'Server error';
                                            $.bs.displayErrorMessage(reply.error, 'ajax');
                                            return;
                                        }
                                        if ('ok' == reply.result)
                                        {
                                            $this.dialog('close');
                                            
                                            // if it was 'Add' button pressed
                                            if (! id)
                                            {
                                                // change 'Add' button to 'Edit' + set specified id
                                                
                                                $.bs.recipients[data_field][data_id].id = reply.id;
                                                if (! $.bs.recipients[data_field][data_id].type)
                                                    $.bs.recipients[data_field][data_id].type = address.indexOf('@') ? 'email' : 'fax';
                                                btn.val('Edit Contact');
                                            }

                                            // update data of all recipients registered in the OM under this contact
                                            for (var u_field in $.bs.recipients) {
                                                for (var u_i = 0; u_i < $.bs.recipients[u_field].length; u_i++) {
                                                    if (
                                                        $.bs.recipients[u_field][u_i].id == reply.id
                                                    ) {
                                                        $.bs.recipients[u_field][u_i].name = reply.name;
                                                        $.bs.recipients[u_field][u_i].company_id = reply.company_id;
                                                        $.bs.recipients[u_field][u_i].company_name = reply.company_name;
                                                        $.bs.recipients[u_field][u_i].address = (
                                                            'email' == $.bs.recipients[u_field][u_i].type
                                                                ? reply.email_address
                                                                : reply.fax_phone);
                                                    }
                                                    
                                                }
                                            }
                                            
                                            // redraw all recipients by OM
                                            $compose.drawRecipients();
                                        }
                                    }
                                });
                                
                            },
                            'Cancel' : function() {
                                var $this = $(this);
                                $this.dialog('close');
                            }
                        })
                .html(html)
                .bs_dialog_open();
            
        };        

        // create the dialog
        $.bs.recipientContactDlg = $('#recipient-contact-dialog');
        if ( $.bs.recipientContactDlg.length == 0 ) {
            $(document.body).append( $.bs.get_template('recipient_contact_dialog') );
            $.bs.recipientContactDlg = $('#recipient-contact-dialog');

            // open the dialog in preview (loader) mode with spinner
            $.bs.recipientContactDlg
                .bs_dialog({
                    autoOpen: false,
                    width: 450,
                    height: 300,
                    minWidth: 350,
                    minHeight: 200,
                    bgiframe: true
                });
        }

        // if we edit some existing (attached to recipient) contact
        if (id)
        {
            // load the (contact + companies) and open dialog
            setSpinner();
            $.ajax({
                url: "/contacts/person/load",
                type: 'POST',
                dataType: 'json',
                data: 'id=' + id,
                success: function(json) {
                    var data = json.Result;
                    if ('ok' == data.result)
                    {
                        // set dialog form with data
                        setData(data);
                    } else {
                        $.bs.recipientContactDlg.dialog('close');
                    }
                },
                error: function() {
                    $.bs.recipientContactDlg.dialog('close');
                }
            });
            
        } else { // we need blank form to create new contact
            
            // load the companies of current user and open dialog in blank mode
            setSpinner();
            $.ajax({
                url: "/contacts/person/load_companies",
                type: 'POST',
                dataType: 'json',
                data: '',
                success: function(json) {
                    var data = json.Result;
                    if ('ok' == data.result)
                    {
                        // set dialog form with data
                        if (! type) {
                            if (address.indexOf('@') != -1)
                                type = 'email';
                            else if (address.match(/^\+?[\d ]+$/))
                                type = 'fax';
                        }
                        
                        if (! name)
                            name = address;
                        if (!type && name.indexOf(' ') > 0) {
                            // trying to parse "John Doe"-like values
                            data.given_name = name.replace(/ .*$/, '');
                            data.family_name = name.replace(/^.*? /, '');
                        } else
                            data.given_name = name;
                        data.email_address = 'email' == type ? address : '';
                        data.fax_phone = 'fax' == type ? address : '';
                        setData(data);
                    } else {
                        $.bs.recipientContactDlg.dialog('close');
                    }
                },
                error: function() {
                    $.bs.recipientContactDlg.dialog('close');
                }
            });

        }

    },

    // redraw the form at line after changes in resipients set
    drawRecipients: function() {
        var $this = this;
        for (field in $.bs.recipients) {

	        var rows = [];
	        var addr = [];

	        for (i = 0; i < $.bs.recipients[field].length; i++) {
	            data = $.bs.recipients[field][i];
	            data.address = $.trim(data.address);
	            data.name = $.trim(data.name);
	
	            var has_name = data.id && data.address != data.name;
	            var parts = new Array;
	
                var part = $.bs.get_template('recipient_contact', data);
	            if (has_name && part)
	                parts[parts.length] = part;
                part = $.bs.get_template('recipient_company', data);
	            if (data.company_id && part)
	                parts[parts.length] = part;
                if (data.address)
	                parts[parts.length] = data.address;
	
	            rows[rows.length] = $.bs.get_template(
                    'recipient_wrapper', {
                        html: parts.join(', '), 
                        id: i,
                        field: field,
                        edit_title: data['id'] == 0 ? 'Add To Address Book' : 'Edit Contact'
                    }
	            );
	            if (data.type == 'email' && data.id)
	                addr[addr.length] = "e:" + data.id;
	            else if (data.type == 'fax' && data.id)
	                addr[addr.length] = "f:" + data.id;
	            else
	                addr[addr.length] = "p:" + data.address;
	        }
	
	        var container = field + '_recipients';
	        if ($('#' + container).length == 0)
	            $('#' + field).before('<div id="' + container + '" class="recipients hidden" />');
	
	        $('#' + container).html(rows.join('\n')).show();
	
	        var self = this;

	        $('#' + container + ' .row-holder input.btn_delete').click(function() {
	            var id = $(this).attr('id').replace(/del_/, '');
	            var field = id.replace(/_\d+$/, '');
	            id = id.replace(/.*_/, '');

	            $.bs.recipients[field].splice(id, 1);
	            self.drawRecipients();
	        });
	        $('#' + container + ' .row-holder input.btn_edit').click(function() {
                var $this = $(this);
	            var id = $this.attr('id').replace(/edit_/, '');
	            var field = id.replace(/_\d+$/, '');
	            id = id.replace(/.*_/, '');

	            var data = $.bs.recipients[field][id];
                $this.contactDialog(
                    $this
                    ,field
                    ,id
                    , data['id']
                    , data['name']
                    , data['type']
                    , data['address']
                );
	        });

					var values_field = field.replace(/_.*/, '_addresses');
	        $('#' + values_field).val(addr.join(","));
	      }
        
        // show/hide limits warning if it needs
        this.showAlertIfPackageAttached();
    },

    
    // toggle mode with/without limits
    showAlertIfPackageAttached : function() {
        var s = "";
        var r_types = $.bs.getRecipientTypes();
        var attached = $('#attach').is(':checked');

        // if attach_file mode and at leat one limit exceeded
        if (($.bs.limit_size_exceeded || $.bs.limit_pages_exceeded) && attached) {
            
            // get limits values
            var ml = $.bs.messageLimits();
            var to_types = r_types;
            
            // get types of recipients email=1, fax=2, both=3 or none=0
            
            // remove specifed type if no such limit exceeded
            if (! $.bs.limit_size_exceeded)
                to_types &= ~1;
            if (! $.bs.limit_pages_exceeded)
                to_types &= ~2;
            
            // compose limits warning text
            if (to_types & 1)
                s += ml.size + " Kb email";
            if (to_types == 3)
                s += ", ";
            if (to_types & 2)
                s += ml.page + " pages fax";
        }

        // if there is some limits warning
        if (s != "") {
            $("#limits_warning_text").text(s);
            $("#limits_warning").show();
            $(".btn_send").attr('disabled', 'disabled');
        } else {
            $("#limits_warning").hide();
            $(".btn_send").attr('disabled', false);
        }

        // show fax alert if there are some fax recipients
        if (r_types & 2 && attached) {
            $('#fax_warning').show();
            $('.td-unfaxable').addClass('unfaxable').attr('title', $.bs.get_template('unfaxable_title'));
        } else {
            $('#fax_warning').hide();
            $('.td-unfaxable').removeClass('unfaxable').attr('title', '');
        }

        if (r_types & 1 && attached)
            $('#propose-send-as-url').show();
        else
            $('#propose-send-as-url').hide();
    }

    
});

$(document).ready(function() {

    var toObject;
    $('.contact').each(function() {
        toObject = $(this);

        toObject.autocomplete('/messages/contacts', {
            minChars: 3,
            cacheLength: 10,
            delay: 200,
            dataType: 'json',
            parse: function(data) {
                var arr = data.Result;
                var parsed = [];
                for (var i = 0; i < arr.length; i++)
                {
                    var data = arr[i];
                    if (! $.bs.hasRecipient(data))
                        parsed[parsed.length] = {
                            data: data,
                            value: arr[i].id,
                            result: arr[i].name
                        };
                }
                return parsed;
            },
            formatItem: function(data, pos, count, q) {
                return data.name + ', ' + (data.company_id ? data.company_name + ', ' : '') + data.address;
            }
        }).result(function(evt, data, formatted) {
            evt.preventDefault();
            toObject.addRecipient(data, $(this));
            $(this).flushCache();
        }).keypress(function(evt) {
            if (evt.keyCode == 13) {
                var val = $(this).val();
                if ($.trim(val).length) {
                    evt.preventDefault();
                    toObject.addRecipient(val, $(this));
                }
            }
        });
    });


    $('.add-contact').click(function() {
        var obj = $(this).parent().find(".contact");
        var val = $.trim(obj.val());
        if (val.length)
            obj.addRecipient(val, obj);
        obj.focus_safe();
    });

    $('#frmCompose').submit(function() {
        $('.add-contact').click();
        return true;
    });

    $('#placement_sidebar').bind('checkSize', function() {
        var ml = $.bs.messageLimits();
        if (!ml.page && !ml.size)
            return;

        var totalPages = 0;
        var totalSize = 0;

        if (!$.bs.current_package() || !$.bs.current_package()['package'])
            return;

        with ($.bs.current_package()['package']) {
            if (!items || !items.length)
                return;
            for (var i = 0; i < items.length; i++) {
                if (("undefined" != typeof items[i].filesize) && items[i].filesize)
                    totalSize += items[i].filesize * 1;  // ololo, parseInt doesn't work here :(
                if (("undefined" != typeof items[i].pages) && items[i].pages)
                    totalPages += items[i].pages * 1; // and here too. looks like magic!
            }
        }
        totalSize = Math.round(totalSize / 1024);

        if ((ml.size && totalSize >= ml.size))
            $.bs.limit_size_exceeded = true;
        if ((ml.page && totalPages >= ml.page))
            $.bs.limit_pages_exceeded = true;
        
        if ((!ml.page || totalPages <= ml.page) && (!ml.size || totalSize <= ml.size))
            return;

        toObject.showAlertIfPackageAttached();
    });
    

    $('#placement_sidebar').bind('changed', function() {
        $(this).trigger('checkSize');
    });

    if(! ($('#attach').is(':checked') || $("#send_as_url").is(":checked")))
    {
        $("#divItems").fadeTo("fast", 0.33);
        $("#divThumb").fadeTo("fast", 0.33);
    }

    var body_footer = false;
    var show_body_footer = function()
    {
        if (body_footer)
            return;
        body_footer = true;
        var body = $('#body');
        var footer = $('#body_footer');
        footer.show();
        body.height(body.height() - footer.height());
    }
    var hide_body_footer = function()
    {
        if (! body_footer)
            return;
        body_footer = false;
        var body = $('#body');
        var footer = $('#body_footer');
        body.height(body.height() + footer.height());
        footer.hide();
    }
    // handle radiobuttons switch
    $("input.chk").click(function(){ 
        if ($("#send_as_url").is(":checked"))
            show_body_footer();
            //$("#body_footer").show();
        else
            hide_body_footer();
            //$("#body_footer").hide();
        if($('#attach').is(':checked') || $("#send_as_url").is(":checked"))
        {
            $("#divItems").fadeTo("normal", 1);
            $("#divThumb").fadeTo("normal", 1);
        } else {
            $("#divItems").fadeTo("normal", 0.33);
            $("#divThumb").fadeTo("normal", 0.33);
        }
        toObject.showAlertIfPackageAttached();
    });

    if ($("#send_as_url").is(":checked"))
        show_body_footer();

    var changed = false;

    $('#sender, #to_addresses, #bcc_addresses, #subject, #body').change(function() {
    	changed = true; 
    });

    var check_unsaved = function() {
        if (! changed)
            return true;
        return confirm("There are unsaved changes on the form. They will be lost if you continue now. Continue?");
    }

    $('a').click(function(){
        if (! check_unsaved())
            return false;
    });
    $('form#form_search').submit(function(){
        if (! check_unsaved())
            return false;
    });

    if ($.bs.n_contacts_cart > 0) {
        if (confirm('You have ' + $.bs.n_contacts_cart + ' checked contacts. Would you like to add them to this message?')) {
            $.ajax({
                url: "/contacts/person/load_contacts_cart",
                type: 'POST',
                dataType: 'json',
                data: '',
                success: function(json) {
                    var data = json.Result;
                    var toObj = $('#to_search_input');
                    var n = data.length;
                    for (var i = 0 ; i < n; ++i)
                        toObj.addRecipient(data[i]);
                },
                error: function() {
                }
            });
        }
    }

});

})(jQuery);
