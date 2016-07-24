$(document).on 'click', 'tr[data-link], input[data-link]', ->
  window.location = @dataset.link
