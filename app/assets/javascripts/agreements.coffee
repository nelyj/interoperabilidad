document.addEventListener 'turbolinks:load', ->
  $("tr[data-link]").click ->
    window.location = @dataset.link
