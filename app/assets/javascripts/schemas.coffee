document.addEventListener 'turbolinks:load', ->
  $('select').select2
    theme: 'bootstrap'
    containerCssClass: ':all:'
  $('pre code').each (i, block) ->
    hljs.highlightBlock(block)
  $('#categories-list li:first').addClass("active")
  filterSchemas($('#categories-list li:first a').attr("data-category"))

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
    $('#input-file, #remove-file').show()
    $('#label-file').hide()
    return

titleize = (string) ->
  string.split(/[\s|_]/).map((s) -> s[0].toUpperCase() + s.slice(1)).join('')


$(document).on 'change', ':file', ->
  input = $(this)
  numFiles = if input.get(0).files then input.get(0).files.length else 1
  label = input.val().replace(/\\/g, '/').replace(/.*\//, '')
  $('#schema_name').val(titleize(label.replace(/\..*$/, '')))
  input.trigger 'fileselect', [
    numFiles
    label
  ]
  return

$(document).on 'click', '#remove-file', ->
  $('#input-file, #remove-file').hide()
  $('#label-file').show()
  $("#input-file, #schema_spec_file, #schema_version_spec_file").val ""


this.filterSchemas = filterSchemas = (category) ->
  dataCategory = '[data-categories="' + category + '"]'
  $('.box-schema.filtered').hide().filter(dataCategory).css("display","inline-block")
  if $('.box-schema.filtered').filter(dataCategory).length == 0
    $('.schema-wrapper .empty-state').show();
  else
    $('.schema-wrapper .empty-state').hide();
    return

addClassToList = (element) ->
  $('#categories-list li').removeClass()
  if !element.hasClass('active')
    element.addClass('active');
    return

$(document).on 'click', '[data-toggle=collapse-next]', (e) ->
  e.preventDefault()
  $(this)
    .closest('.panel')
    .find('.panel-collapse')
    .collapse 'hide'
  $(this)
    .toggleClass('down')
    .parentsUntil('.panel-group', '.panel')
    .children('.panel-collapse:first')
    .collapse 'toggle'
  return