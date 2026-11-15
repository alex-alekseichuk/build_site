(function($) {
    $.bs.template_add('recipient_contact', '<a href="/contacts/person/edit?id=#{id}">#{name}</a>');
    $.bs.template_add('recipient_company', '<a href="/contacts/company/edit?id=#{company_id}">#{company_name}</a>');
    $.bs.template_add('recipient_wrapper',
        '<div class="row-holder">' +
            '<p class="contact-row"><span>#{html}</span>' +
            '<input type="button" class="btn_edit" style="float:right;width:140px;" id="edit_#{field}_#{id}" value="#{edit_title}" />' +
            '</p>' +
            '<input type="button" class="btn_delete" id="del_#{field}_#{id}" value="Delete" />' +
        '</div>'
    );

    $.bs.template_add('recipient_contact_dialog', '<div id="recipient-contact-dialog" title="Addressbook Contact Details" />' );
    $.bs.template_add('recipient_contact_dialog_html',
        '<form class="output_area" style="padding-right:20px;" onsubmit="return false;">'
        + '<input type="hidden" name="id" id="rcd_id" value="#{id}" />'
        + '<table class="basic">'
        + '<tr><td><strong>First Name<strong></td><td><input type="text" name="given_name" id="rcd_given_name" value="#{given_name}" /></td></tr>'
        + '<tr><td>Last Name</td><td><input type="text" name="family_name" id="rcd_family_name" value="#{family_name}" /></td></tr>'
        + '<tr><td>Existing Company</td><td><select name="company" id="rcd_company"><option value=""></options>#{company_options}</select></td></tr>'
        + '<tr><td>or New Company</td><td><input type="text" name="new_company" id="rcd_new_company" value="#{new_company}" /></td></tr>'
        + '<tr><td>Phone #</td><td><input type="text" name="work_phone" id="rcd_work_phone" value="#{work_phone}" /></td></tr>'
        + '<tr><td>Fax #</td><td><input type="text" name="fax_phone" id="rcd_fax_phone" value="#{fax_phone}" /></td></tr>'
        + '<tr><td>Email Address</td><td><input type="text" name="email_address" id="rcd_email_address" value="#{email_address}" /></td></tr>'
        + '</table></form>'
    );

})(jQuery);
