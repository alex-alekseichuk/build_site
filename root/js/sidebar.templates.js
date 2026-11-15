(function($) {
    $.bs.template_add('cps_wrapper', '<div class="b-package">' +
                '<div class="b-package-h">' +
                    '<ul class="b-package-nav">' +
                        '<li><a href="#" class="bt-minimize" id="sidebar_toggle"></a></li>' +
                        '<li id="cps-menu">#{menu}</li>' +
                    '</ul>' +
                    '<h3>Current Package</h3>' +
                '</div>' +
                '<div class="items" id="sidebar_context" />' +
                '<div class="controls" id="sidebar-size"></div>' +
            '</div>'
    );
    
    $.bs.template_add('cps_dialog_menu', 
            '<a href="#" class="bt-context" id="sidebar_menu"></a>' + 
            '<div id="drop-wrapper">' + 
            '<ul class="drop">' +
                '<li><a menu_id="view" href="/folders/edit?file_id=#{id}">View Package</a></li>' +
                '<li><a menu_id="send" href="/messages/package?package_id=#{id}">Send Package</a></li>' +
                '<li><a menu_id="print" href="/print?package_id=#{id}&all=1">Print Package</a></li>' +
                '<li><a menu_id="attach" href="/jspackage/upload">Attach File</a></li>' +
                '<li><a menu_id="switch" href="/jspackage/switch">Switch Package</a></li>' +
                '<li><a menu_id="save" href="/folders/save">Save Package</a></li>' +
                '<li class="last"><a menu_id="blank" href="/jspackage/blank">New Package</a></li>' +
            '</ul>' + 
            '</div>'
    );

    $.bs.template_add('cps_dialog_switch_wrapper',
                '<div style="display: none" id="switch-dialog" title="Switch Package">'+
                '</div>'
    );

    $.bs.template_add('cps_dialog_switch_html',
        '<label for="switch-select">Select a package to switch to:<br /> </label>' +
        '<select id="switch-select">' +
        '#{options}' +
        '</select>'
    );

    $.bs.template_add('cps_dialog_switch_alert',
        '<p class="warning">Current package is unsaved now. Click <a href="#" id="alert-save-link">here</a> to save the package before switching.</p>'
    );

    $.bs.template_add('cps_items_summary', '<a href="/folders/edit?file_id=#{id}"><strong> #{count_package_items} #{label_item} </strong>&nbsp; (#{count_product_items} #{label_product})</a>');
    $.bs.template_add('cps_toc_link','<li>' +
                    '<div class="toc-link-cont">' +
                        '<span class="ico_plus"></span><a target="_blank" href="/jstoc/toc_pdf?id=#{id}">#{label}</a>' +
                        '<a class="edit-toc" href="/folders/edit?file_id=#{id}">edit</a>' +
                    '</div>' +
                    '<div id="toc-preview" class="hidden"><img id="img-toc-preview" alt="TOC preview..." src="/images/misc/1.gif" width="250" /></div>' +
                '</li>');
    $.bs.template_add('cps_dnd_container', '<div class="dad_filedoc_container">' +
                    '&nbsp;#{content}&nbsp;' +
                    '</div>');
    $.bs.template_add('cps_product_container', '<li class="product">' +
                            '<div class="ico">'+
                                '<ul>' +
                                    '<li><a operation_type="delete_product" '+
                                                'object_id="#{item_id}" '+
                                                'href="/jspackage/remove_product?product_id=#{item_id}">Delete product</a>'+
                                    '</li>'+
                                    '<li>' +
                                        '<a operation_type="print" ' +
                                                'object_id=#{object_id}" ' +
                                                'href="/print?package_id=#{package_id}&product_id=#{item_id}">Print product</a>'+
                                    '</li>'+
                                "</ul>"+
                            "</div>" +
                            '<a class="product" href="#{linkhref}">#{item_title}</a>' +
                            '<ul>#{sub_items}</ul>' +
                        "</li>");
    $.bs.template_add('cps_item_container', "<li>" +
                        "<div class='ico'>"+
                            "<ul>"+
                                '<li><a operation_type="delete" '+
                                            'object_type="#{object_type}" '+
                                            'object_id="#{object_id}" '+
                                            'href="/jspackage/remove_item?#{item_params}">Delete #{object_type}</a>'+
                                '</li>'+
                                '<li><a href="/print?package_id=#{package_id}&#{object_type}_id=#{object_id}">Print #{object_type}</a></li>'+
								'<li><a href="/annotation/edit/#{package_item_id}">Annotate</a></li>'+
                            "</ul>"+
                        "</div>" +
                        '<a target="_blank" objectid="#{package_item_id}" class="#{object_type}" target="_blank" href="#{linkhref}" title="#{item_title}">#{short_title}</a>' +
                    "</li>");

		$.bs.template_add("cps_clear_confirmation", " Are you sure you want to clear this package?  You will lose any unsaved changes.");
})(jQuery);
