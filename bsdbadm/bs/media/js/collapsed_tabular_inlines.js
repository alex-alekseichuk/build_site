jQuery(function($) {
    // Only for tabular inlines
    $('div.inline-group div.inline-related.tabular:not(.liked)').each(function() {
        fs = $(this).find('fieldset')
        h2 = $(this).find('h2:first')

        // Don't collapse if fieldset contains errors
        if (fs.find('div').hasClass('errors'))
            fs.addClass('tabular_collapse');
        else
            fs.addClass('tabular_collapse collapsed');

        // Add toggle link
        h2.append(' (<a class="tabular_collapse-toggle collapse-toggle" href="#">' + gettext('Show') + '</a>)');
        h2.find('a.tabular_collapse-toggle').bind("click", function(){
            fs = $(this).parent('h2').parent('fieldset');
            if (!fs.hasClass('collapsed'))
            {
                fs.addClass('collapsed');
                $(this).html(gettext('Show'));
            }
            else
            {
                fs.removeClass('collapsed');
                $(this).html(gettext('Hide'));
            }
            return false;
        }).css('cursor', 'pointer').show();
    });
});