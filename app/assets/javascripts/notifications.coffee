$ ->
  $("tr[data-link]").click ->
    window.location = @dataset.link
