;(function($) {
	$(document).ready(function() {
		$('.expandable .more label').click(function() {
			var $this = $(this);
			var _exp = $this.is('.expandable') ? $this : $this.parents('.expandable:first');
			_exp.toggleClass('expanded');
		});
	});
})(jQuery);
