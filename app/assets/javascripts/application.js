// = require jquery
// = require bootstrap
// = require turbolinks
// = require select2.full
$(document).ready(function() {
    $("select").select2({
        theme: "bootstrap",
        containerCssClass: ":all:"
    });
});