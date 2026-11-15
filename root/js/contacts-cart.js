(function($) {
    $.bs.contacts_cart = {
        // this method is called right after contacts list loading
        // in the template
        // if there is at least one contact item
        init: function() {
            // add or remove contact to/from cart
            var contacts_cart_add_remove = function(event) {
                var element = event.target;
                var jElement = jQuery( element );
                if ( jElement.length == 0 ) {
                    alert('see errror');
                    return;
                }

                var str = '';
                if ( jElement.attr('checked') )
                    str = 'cart_add';
                else
                    str = 'cart_remove';
                str += '?type=' + jElement.attr('contact_type') + '&contact_id=' + jElement.val();
                str += "&q=" + Math.random();

                jElement.addClass('novisible');
                jElement.parent().addClass('wait');


                jQuery.getJSON( '/contacts/person/'+str, function(data) {
                    jElement.removeClass('novisible');
                    jElement.parent().removeClass('wait');
                } );
            }

            // init contacts checkboxes
            jQuery('input[name="chkContact"]').click( contacts_cart_add_remove );
            jQuery('input[name="chkContact"]').each(function(i, elem) {
                var jElement = jQuery(elem);
                var contact_id = jElement.val();
                var type = jElement.attr('contact_type');
                var n = contacts_cart.length;
                jElement.show();
                jElement.attr('checked', false);
                for (var i = 0; i < n; ++i)
                    if (contacts_cart[i].contact_id == contact_id && contacts_cart[i].type == type) {
                        jElement.attr('checked', true);
                        break;
                    }
            });
        }
    };
	
})(jQuery);

$(function(){
	$.bs.contacts_cart.init();
});
