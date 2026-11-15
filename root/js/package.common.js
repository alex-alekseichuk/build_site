;(function($) {
$(document).ready(function() {

    $.bs.template_add('clear_confirmation', 'Clearing this package will remove all products/documents that have been added. Continue?');

    var $pts = $('#toc-type-switcher');
    $form = $('#package-details');

    if ($.bs.can_write_file()) {
        $pts.find('#toc-type').change(function() {
            location = '/jstoc/switch_toc?' + "package_id=" + item.id + "&template_name=" + $(this).val();
            //$pts.submit();
        });

        $notice = $form.find('.autosave-notice');

        $form.find(':input').change(function() {
            $.ajax({
                url: $form.attr('action'),
                data: $('#package-details').serialize() + '&ajax=1',
                type: $form.attr('method'),
                dataType: 'json',
                
                beforeSend: function() {
                    $notice.html($.bs.get_template('details_autosaving'));
                    $notice.addClass('ajax');
                },

                success: function(data) {
                    if (data.Result.file) {
                        var dt = new Date;
                        $notice.html($.bs.get_template('details_autosaved', {
                            date: $.bs.time()
                        }));
                        $notice.removeClass('ajax');
                    }
                }           
            });
        });

        $('#action-makecurrent').click(function() {
            var $btn = $(this);
            var callback = function() {
                $.ajax({
                    url: '/jspackage/make_current', 
                    data:{ package_id: item.id }, 
                    beforeSend: function() {
                        $btn.spinner_button();
                    },
                    success: function() {
                        $btn.clear_spinner();
                        $btn.attr('disabled', 'disabled');
                    }
                });
            }

            if ($.bs.should_save_package()) {
                $.bs.package_destructive_dialog(this, callback);
                return false;
            } else 
                callback();
        });
    
        $('.table-action-clear').click(function() {
            if (!confirm($.bs.get_template('clear_confirmation')))
                return;
            var $btn = $(this);
            $.ajax({
                url: '/jspackage/clear',
                data: { package_id: item.id },
                beforeSend: function() {
                    $btn.spinner_button();
                },
                success: function() {
                    $btn.clear_spinner();
                    document.location = document.location;
                }
            });
            
        });

        $('#action-save').click(function() {
            $.bs.save_package(item.id, function() {
                document.location = document.location;
            });
        });
    } else {
        // readonly mode
        $pts.find('#toc-type').attr('disabled', 'disabled');
        $form.find(':input').attr('disabled', 'disabled');
        $('#action-save').attr('disabled', 'disabled');
        $('#action-makecurrent').attr('disabled', 'disabled');
        $('#action-delete').attr('disabled', 'disabled');
        $('#action-save').attr('disabled', 'disabled');
        $('.table-action-attach').attr('disabled', 'disabled');
        $('.table-action-clear').attr('disabled', 'disabled');
        $('.table-action-save').attr('disabled', 'disabled');
        $('.btn_toc_add').attr('disabled', 'disabled');
    }

    if ($.browser.msie) {
        $('#action-print').removeAttr('disabled');
    }
    
    $('#action-bar input[redirect]').click(function() {
        document.location = $(this).attr('redirect');
    });
    $('#action-bar input[redirect_new]').click(function() {
        window.open($(this).attr('redirect_new'));
    });


});
})(jQuery);
