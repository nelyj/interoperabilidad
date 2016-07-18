document.addEventListener 'turbolinks:load', ->
  $("tr[data-link]").click ->
    window.location = @dataset.link

document.addEventListener 'turbolinks:load', ->
  $("input[data-link]").click ->
    window.location = @dataset.link
