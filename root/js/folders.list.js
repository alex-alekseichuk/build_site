if(jQuery) (function($){
	$.bs.template_add('delete_confirm',
		'<div style="display: none" id="delete-confirm-dialog" title="Delete folder">' +
			'<form action="#{url}" method="post">' +
			'<input type="hidden" name="confirm" value="1" />' +
			'<p>All files of the folder will be removed.</p>' +
			'</form>' +
		'</div>'
	);


	$(document).ready( function() {
		var alt = $('#action-delete').attr('alt');
		$('#action-delete').click(function() {
			var dlg = jQuery('#delete-confirm-dialog');
			if ( dlg.length == 0 ) {
				$(document.body).append( $.bs.get_template('delete_confirm', {
					url: alt
				}));
				dlg = jQuery('#delete-confirm-dialog');
				dlg.bs_dialog({
						autoOpen: false
					});
			}
			
			var buttons = {
				'Continue': function() {
					dlg.spinner_dialog();
					dlg.find('form').submit();
				},
				'Cancel': function() {
					dlg.dialog('close');
				}
			}

			dlg
			.dialog('option', 'buttons', buttons)
			.bs_dialog_open();
		}).removeAttr('alt');

		$('#action-bar input[alt]').click(function() {
			document.location = $(this).attr('alt');
		});
	});
})(jQuery);
