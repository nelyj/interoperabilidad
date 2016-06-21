document.addEventListener 'turbolinks:load', ->
  $('select').select2
    theme: 'bootstrap'
    containerCssClass: ':all:'

filterSchemas = (category) ->
  dataCategory = '[data-categories*="' + category + '"]'
  $('.box-schema').hide().filter(dataCategory).show()
  return

$(document).on 'click', '.box-col-categories ul li a', (e) ->
  selectCategory = $(this).data('category')
  filterSchemas(selectCategory)
  e.preventDefault()
  return

$(document).on 'fileselect', ':file', (event, numFiles, label) ->
  input = $(this).parents('.input-group').find(':text')
  log = if numFiles > 1 then numFiles + ' files selected' else label
  if input.length
    input.val log
    $('#input-file, #remove-file').show()
    $('#label-file').hide()
    return

$(document).on 'change', ':file', ->
  input = $(this)
  numFiles = if input.get(0).files then input.get(0).files.length else 1
  label = input.val().replace(/\\/g, '/').replace(/.*\//, '')
  input.trigger 'fileselect', [
    numFiles
    label
  ]
  return

$(document).on 'click', '#remove-file', ->
  $('#input-file, #remove-file').hide()
  $('#label-file').show()
  $("input").val ""