var currentPageNumber;
var editor;
var switching = false;

$(window).resize(function(){
    layout();
    if (editor)
        editor.draw.setSize($('div#editor').width(), $('div#editor').height());
});

$( function(){
    layout();
    editor = new VectorEditor($('div#editor')[0], $('div#editor').width(), $('div#editor').height());
    setFillColor("#FFFFFF");
    setLineColor("#000000");
    setLineWidth(1);
    setLineOpacity(1);
    setFillOpacity(0);
    setEditorMode("select");
    setCurrentPage(1);

    editor.on("setmode",function(mode)
    {
        if (mode == "delete")
        {
            editor.lastmode = "select";
        }
    });

    // FIXME: workaround, needs editor events system update
    $(document).everyTime(100, hideOptionsIfUnselected);

    editor.on("select", function(event, shape)
    {
        $('#fillOptions').hide();
        $('#lineOptions').hide();
        $('#fontOptions').hide();

        switch (shape.type)
        {
            case "rect": case "ellipse":
                $('#fillOptions').show();
                // FIXME: should be done through val() when events system is improved
                $('#fillColor+.color_picker').css('background-color',shape.attr('fill'));
                $('#fillOpacity').val(shape.attr('fill-opacity'));
            case "line": case "path":
                $('#lineOptions').show();
                // FIXME: should be done through val() when events system is improved
                $('#lineColor+.color_picker').css('background-color', shape.attr('stroke'));
                $('#lineOpacity').val(shape.attr('stroke-opacity'));
                $('#lineWidth').val(shape.attr('stroke-width'));
                break;
            case "text":
                $('#fontOptions').show();
                $('#fontColor+.color_picker').css('background-color', shape.attr('stroke'));
                // TODO font size and family
        }
    });

    $('#lineColor').change(function(){
        setLineColor($(this).val());
    });
    $('#lineWidth').change(function(){
        setLineWidth(parseInt($(this).val()));
    });
    $('#lineOpacity').change(function(){
        setLineOpacity(parseFloat($(this).val()));
    });
    $('#fillColor').change(function(){
        setFillColor($(this).val());
    });
    $('#fillOpacity').change(function(){
        setFillOpacity(parseFloat($(this).val()));
    });
    $('#fontColor').change(function(){
        setFontColor($(this).val());
    });

    $('button#select').click(function(){
        $('#fillOptions').hide();
        $('#lineOptions').hide();
        $('#fontOptions').hide();
        setEditorMode('select');
    });
    $('button#rect').click(function(){
        $('#fillOptions').show();
        $('#lineOptions').show();
        $('#fontOptions').hide();
        setEditorMode('rect');
    });
    $('button#line').click(function(){
        $('#fillOptions').hide();
        $('#lineOptions').show();
        $('#fontOptions').hide();
        setEditorMode('line');
    });
    $('button#ellipse').click(function(){
        $('#fillOptions').show();
        $('#lineOptions').show();
        $('#fontOptions').hide();
        setEditorMode('ellipse');
    });
    $('button#path').click(function(){
        $('#fillOptions').hide();
        $('#lineOptions').show();
        $('#fontOptions').hide();
        $('#fillOpacity').val(0);
        setFillOpacity(0);
        setEditorMode('path');
    });
    $('button#text').click(function(){
        $('#fillOptions').hide();
        $('#lineOptions').hide();
        $('#fontOptions').show();
        setEditorMode('text');
    });
    $('button#delete').click(function(){
        $('#fillOptions').hide();
        $('#lineOptions').hide();
        $('#fontOptions').hide();
        setEditorMode('delete');
        $('button#select').click();
    });

    $('.thumb .delete').click(function(){
        var thumb = $(this).parent().parent();
        var pageNumber = thumb.children('.page-number').text();
        deletePage(pageNumber);
        return false;
    });

    $('.thumb .restore').click(function(){
        var thumb = $(this).parent().parent();
        var pageNumber = thumb.children('.page-number').text();
        undeletePage(pageNumber);
        return false;
    });

    $('#main .restore').click(function(){
        undeletePage(currentPageNumber);
        return false;
    });

    $('#main .delete').click(function(){
        deletePage(currentPageNumber);
        return false;
    });

    $('#header #restore-all').click(function(){
        for (var i = 1; i <= totalPages; ++i)
        {
            undeletePage(i);
        }
        return false;
    });

    $('#header #delete-all').click(function(){
        for (var i = 1; i <= totalPages; ++i)
        {
            deletePage(i);
        }
        return false;
    });

    $('#header #download-pdf').click(function(){
        $('#main').addClass('blocked');        
        $.ajax({url: '/crunch/file/' + fileId + '/download/',
            type: 'GET',
            cache: false,
            success: function(data)
            {
                $('#main').removeClass('blocked');
                $('<iframe></iframe>').hide().attr('src', data + '/?_=' + Math.random()).
                    appendTo($('body'));
            }
        });

        return false;

    });

    $('.thumb>img').click(function(){
        var thumb = $(this).parent();
        var pageNumber = thumb.children('.page-number').text();
        setCurrentPage(pageNumber);
        return false;
    });

    $('.thumb .overlay').click(function(){
        var thumb = $(this).parent();
        var pageNumber = thumb.children('.page-number').text();
        setCurrentPage(pageNumber);
        return false;
    });

    $('#prev-page').click(function()
    {
        if (currentPageNumber > 1)
        {
            currentPageNumber -= 1;
            setCurrentPage(currentPageNumber);
        }
    });

    $('#next-page').click(function()
    {
        if (currentPageNumber < totalPages)
        {
            currentPageNumber += 1;
            setCurrentPage(currentPageNumber);
        }
    });

    $('#paging-form').submit(function()
    {
        var pageNumber = parseInt($('#currentPageInput').val());
        $('#currentPageInput').val(currentPageNumber);
        if (isNaN(pageNumber))
        {
            return false;
        }
        $('#currentPageInput').val(pageNumber);
        if (pageNumber == currentPageNumber)
        {
            return false;
        }
        if (pageNumber < 1)
        {
            pageNumber = 1;
        }
        if (pageNumber > totalPages)
        {
            pageNumber = totalPages;
        }
        setCurrentPage(pageNumber);
        return false;
    });

    $(document).everyTime(10000, function(){
        if (editor && !switching && currentPageNumber)
            saveMarkup(currentPageNumber);
    });
})

$(window).unload(function(){
    saveMarkup(currentPageNumber);
});

function hideOptionsIfUnselected()
{
    // FIXME: hack, needs better editor's events system
    if (!editor.selected.length && (editor.mode == "select"))
    {
        $('#fillOptions').hide();
        $('#lineOptions').hide();
        $('#fontOptions').hide();
    }
}

function setEditorMode(mode)
{
    if(mode == "text")
    {
        // TODO: make the text field shown
        editor.prop.text = prompt("Text:",editor.prop.text)
    }
    else if(mode == "image")
    {
        editor.prop.src = prompt("Image Source URL:",editor.prop.src)
    }
    $("#tools>button").attr("disabled",null);
    $("#tools>button#"+mode).attr("disabled","true");
    editor.setMode(mode=='selectp'?'select+':mode);
}

function setFillColor(color) 
{
    editor.set("fill", color)
}

function setFontColor(color) 
{
    setFillColor(color);
    setLineColor(color);
    setLineOpacity(1);
    setFillOpacity(1);
}

function setLineColor(color) 
{
    editor.set("stroke", color);
}

function setLineWidth(width)
{
    editor.set("stroke-width", width);
}

function setLineOpacity(opacity) 
{
    editor.set("stroke-opacity", opacity)
}

function setFillOpacity(opacity) 
{
    editor.set("fill-opacity", opacity)
}

function saveMarkup(pageNumber)
{
    if (switching)
        return;
    $.ajax({url: '/crunch/file/' + fileId + '/annotations/' + pageNumber + '/',
        type: 'POST',
        cache: false,
        datatType: 'json',
        data: {
	    'svg_markup': editor.getMarkup(), 
	    'json_markup': editor.getJSON()
            //'is_active': $('.page-number:eq('+ (pageNumber-1) +')').parent().hasClass('deleted')
	}
    });

}

function setCurrentPage(pageNumber)
{
    // block the canvas
    $('#main').addClass('blocked');
    // save current markup
    if (currentPageNumber)
        saveMarkup(currentPageNumber);
    switching = true;
    // unselect current thumbnail
    $('.thumb').removeClass('selected');
    // select the new thumb
    var thumb = $('.page-number:eq('+ (pageNumber-1) +')').parent();
    $('#sidebar').scrollTo(thumb, 500);
    thumb.addClass('selected');
    if (thumb.hasClass('deleted'))
    {
        $('#main').addClass('deleted-page');
    }
    else
    {
        $('#main').removeClass('deleted-page');
    }
    // change the current page number
    pageNumber = parseInt(pageNumber);
    $('#currentPageInput').val(pageNumber);
    // set the scrolling arrows according to the page number
    $('#prev-page').attr('src', '/static/img/arrow_left' + (pageNumber == 1 ? '_disabled' : '') + '_icon.png');
    $('#next-page').attr('src', '/static/img/arrow_right' + (pageNumber == totalPages ? '_disabled' : '') + '_icon.png');

    // prepare the async operations
    var img = new Image(), cnt = 0, json = null, tlabel="load_markup_" + Math.random();
    $(img).load(function() { cnt++; });
    // the loading itself
    img.src = image_path(fileId, pageNumber);
    $.ajax({url: '/crunch/file/' + fileId + '/annotations/' + pageNumber + '/',
        type: 'GET',
        cache: false,
        datatType: 'json',
        success: function(data) { json = data; cnt++; }
    });
    // constantly check if both operations completed
    $(document).everyTime(100, tlabel, function(){
        if (cnt < 2)
            return;
        // kill this timer
        $(document).stopTime(tlabel);
        // put the image, resize the editor svg
        $('img#current-page').attr('src', img.src);
	$('#wrap-canvas').width(img.width).height(img.height);
        editor.draw.setSize($('div#editor').width(), $('div#editor').height());
        // clear editor's surface
        editor.deleteAll();
        editor.setJSON(json);
        // unblock the canvas
        $('#main').removeClass('blocked');
        currentPageNumber = pageNumber;
        switching = false;
    });
}

function deletePage(pageNumber)
{
    // TODO: show spinner, change image on success or failure
    $.ajax({url: '/crunch/file/' + fileId + '/annotations/' + pageNumber + '/',
        type: 'POST',
        cache: false,
        datatType: 'json',
        data: {'is_active': false}
    });
    isCurrent = (pageNumber == currentPageNumber);
    $('.page-number:eq('+ (pageNumber-1) +')').parent().addClass('deleted');
    if (isCurrent)
    {
        $('#main').addClass('deleted-page');
    }
}

function undeletePage(pageNumber)
{
    // TODO: show spinner, change image on success or failure
    $.ajax({url: '/crunch/file/' + fileId + '/annotations/' + pageNumber + '/',
        type: 'POST',
        cache: false,
        datatType: 'json',
        data: {'is_active': true}
    });
    isCurrent = (pageNumber == currentPageNumber);
    $('.page-number:eq('+ (pageNumber-1) +')').parent().removeClass('deleted');
    if (isCurrent)
    {
        $('#main').removeClass('deleted-page');
    }
}

IMAGE_PATH_PREFIX = '/pdf_images/'
function image_path(fileId, pageNumber)
{
    return IMAGE_PATH_PREFIX + fileId + '/' + pageNumber + '.png';
}

/* Layout */
function layout()
{
    layoutFillVert('#wrap-inner');
    $('#main').height($('#wrap-inner').height()-10);
    layoutFillVert('#canvas');
}

function layoutFillVert(box)
{
    var space = $(box).parent().height();
    for (var i = 0; i < $(box).siblings().length; i++)
    {
        space -= $(box).siblings().get(i).offsetHeight;
    }
    $(box).height(space);
}

/* editor improvements */

VectorEditor.prototype.getJSON = function()
{
    var attr = "cx,cy,fill,fill-opacity,font,font-family,font-size,font-weight,gradient,height,opacity,path,r,rotation,rx,ry,src,stroke,stroke-dasharray,stroke-opacity,stroke-width,width,x,y,text".split(",");
    function dumpShape (shape)
    {
        var info = {
            type: shape.type,
            id: shape.id,
            subtype: shape.subtype
        }
        for (var i = 0; i < attr.length; i++)
        {
            var tmp = shape.attr(attr[i]);
            if (tmp != undefined)
            {
                if (attr[i] == "path"){
                    tmp = tmp.toString();
                }
                info[attr[i]] = tmp;
            }
        }
        return info;
    }
    return encode(jQuery.map(this.shapes || [], dumpShape));
}

VectorEditor.prototype.setJSON = function(info)
{
    var instance = this;
    function loadShape(shape, noattachlistener)
    {
        if(!shape || !shape.type || !shape.id)
            return;
        var newshape = null, draw = instance.draw;
        if(!(newshape=editor.getShapeById(shape.id)))
        {
            if (shape.type == "rect")
            {
                newshape = draw.rect(0, 0,0, 0)
            }
            else if (shape.type == "path")
            {
                newshape = draw.path("")
            }
            else if(shape.type == "image")
            {
                newshape = draw.image(shape.src, 0, 0, 0, 0)
            }
            else if(shape.type == "ellipse")
            {
                newshape = draw.ellipse(0, 0, 0, 0)
            }
            else if(shape.type == "text")
            {
                newshape = draw.text(0, 0, shape.text)
            }
        }
        newshape.attr(shape);
        newshape.id = shape.id;
        newshape.subtype = shape.subtype;

        if (!noattachlistener)
        {
            instance.addShape(newshape, true)
        }
    }

    try
    {
        var json = eval("("+ info +")");
        jQuery(json).each(function(index, item){
            loadShape(item);
        });
        return true;
    }
    catch (err)
    {
        return false;
    }
}
