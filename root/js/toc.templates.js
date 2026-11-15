(function($) {
	$.bs.template_add('toc_autocomplete_header', '<th>Product</th><th>Category</th><th>Manufacturer</th>');
	$.bs.template_add('toc_autocomplete_row', '<td>#{title}</td><td>#{category_id} - #{category}</td><td>#{manufacturer}</td>');
	$.bs.template_add('toc_item', 
		'<table class="toc_item"><tr><td style="width:14px;"><img class="toc_item_menu" src="/images/icons/document.gif" /></td>' +
		'<td><a href="#{link}" target="_blank">#{name} #{size}</a></td>' + 
		'<td style="text-align:right;"><a href="#" class="deleteitem">x</a></td></tr></table>'
	);
	$.bs.template_add('toc_item_ro', 
		'<table class="toc_item"><tr><td style="width:14px;"><img class="toc_item_menu_ro" src="/images/icons/document.gif" /></td>' +
		'<td><a href="#{link}" target="_blank">#{name} #{size}</a></td>' + 
		'</tr></table>'
	);
})(jQuery);
