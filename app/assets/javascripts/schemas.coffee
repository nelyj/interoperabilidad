document.addEventListener 'turbolinks:load', ->
  $('select').select2
    theme: 'bootstrap'
    containerCssClass: ':all:'

$(document).on 'click', '#categories-list li a', (e) ->
  e.preventDefault()
  $parent = $(this).parent()
  filterSchemas($(this).data('category'))
  addClassToList($parent)

$(document).on 'fileselect', ':file', (event, numFiles, label) ->
  input = $(this).parents('.input-group').find(':text')
  log = if numFiles > 1 then numFiles + ' files selected' else label
  if input.length
    input.val log
    $('#schema_spec_file, #remove-file').show()
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
  $('#schema_spec_file, #remove-file').hide()
  $('#label-file').show()
  $("input").val ""

filterSchemas = (category) ->
  dataCategory = '[data-categories*="' + category + '"]'
  $('.box-schema').hide().filter(dataCategory).show()
  return

addClassToList = (element) ->
  $('#categories-list li').removeClass()
  if !$element.hasClass('active')
    $element.addClass('active');
    return