$(function () {
    if (!document.URL.match(/\/add\/$/)) {
        return;
    }
    $("#id_product_id").change(function () {
        this._changed = this.value.match(/^\s*$/) ? false : true;
    });
    handler = function() {
        var e = $("#id_product_id")[0];
        if (!e._changed) {
            var value = this.value;
            value = value.toLowerCase();
            value = value.replace(/[^a-z0-9]/g, "_");
            value = value.replace(/^_+|_+$/g, "");
            value = value.replace(/_+/g, "_");
            e.value = value;
        }
    }
    $("#id_product_name").keyup(handler);
    $("#id_product_name").click(handler);
});

