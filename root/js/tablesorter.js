;(function($) {
    $(document).ready(function() {
        var params = {};
        var headers = {};
        var types = {};
        var i = 0;
        var j = 0;
        $("th").each(
                function()
                {
                    if (!$(this).hasClass("sorter"))
                    {
                        headers[i] = {sorter : false};
                    }
                    i++;
                }
        )
        params.headers = headers;
        var textExtraction = function(node)
        {
            var type = '';
            var $node = $(node);

            if ($node.hasClass('number'))
                type = 'number';
            else if ($node.hasClass('string'))
                type = 'string';
            else if ($node.hasClass('category'))
                type = 'category';

            var nodeHTML = $node.html();
            var nodeText = nodeHTML.replace(/\n/g, '');
            nodeText = nodeText.replace(/<div.*?<\/div>/, '');
            nodeText = nodeText.replace(/(<[^<>]*?>)/g, '');
            nodeText = nodeText.replace(/^\s+/, '');

            if ($node.parent().hasClass('folder'))
                return '_a' + nodeText + 'a';

            if ($node.parent().hasClass('file')) {
                if ($node.hasClass('filesize')) {
                    nodeText = nodeText.replace(/\s*Kb.*/, '');
                    return nodeText == '' ? 0 : nodeText;
                } else {
                    return '_b' + nodeText + 'a';
                }
            }
            if ($node.parent().hasClass('archive'))
                return '_c' + nodeText + 'a';
            
            switch (type) {
                case 'string':
                    return "_" + nodeText;
                break;
                case 'number':
                    nodeText = nodeText.replace(/^\D*/, '');
                    nodeText = nodeText.replace(/\D.*$/, '');
                    return nodeText == '' ? '-1' : nodeText;
                break;
                case 'category':
                    return $node.attr('id');
                break;
                
                default:
                    return nodeText;
            }
        }
		if ($.browser.msie && $('table.tablesorter tr').length > 50)
			params.delayCache = true;
        params.textExtraction = textExtraction;
        $("table.tablesorter").tablesorter(params);
    });
})(jQuery);