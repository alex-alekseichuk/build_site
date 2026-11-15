
$(function () {
    $('input[type=text]:regex(id,id_publication_set-\\d+-publication_id)').click(function () {
        if (! $(this).val()) {
            $(this).val( $("#id_company_id").val() )
        }
    });
});
