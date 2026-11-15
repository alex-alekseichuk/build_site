jQuery(function($) {
    function add_link() {
        $(this).after("&nbsp;<a class='changelink' href='#' target='_blank'></a>");
        $(this).next().click(function() {
            var linkvalue = $(this).prev().prev().attr('value');
            if (linkvalue) {
                this.href = $(this).prev().attr('href') + '../' + djangoQuote(linkvalue);
            }
            else {
                this.href = $(this).prev().attr('href').replace("add/", "") + "?t=pk";
            }
            //var win = window.open(linkname, link, 'height=600,width=1000,resizable=yes,scrollbars=yes');
            //win.focus();
            return true;
        });
    }

    $("select+a.add-another").each(add_link);
    $("input[type='text']+a.add-another").each(add_link);
});
