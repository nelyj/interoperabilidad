document.addEventListener 'turbolinks:load', ->
  $('select').select2
    theme: 'bootstrap'
    containerCssClass: ':all:'
    width: 'resolve'
  $('pre code').each (i, block) ->
    hljs.highlightBlock(block)
  #$('#categories-list li:first').addClass("active")
  #filterSchemas($('#categories-list li:first a').attr("data-category"))

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
    return

titleize = (string) ->
  string.split(/[\s|_|-]/).filter(
    (s) -> s.length > 0
  ).map(
    (s) -> s[0].toUpperCase() + s.slice(1)
  ).join('')

$(document).on 'change', ':file', ->
  input = $(this)
  numFiles = if input.get(0).files then input.get(0).files.length else 1
  label = input.val().replace(/\\/g, '/').replace(/.*\//, '').replace(/\.[^\.]*$/, '')
  $('#schema_name, #service_name').val(titleize(label))
  input.trigger 'fileselect', [
    numFiles
    label
  ]
  return

$(document).on 'click', '#remove-file', ->
  $("#input-file, #schema_spec_file, #schema_version_spec_file").val("")
  $("#service_spec_file, #service_version_spec_file").val("")
  $(this).hide()

this.filterSchemas = filterSchemas = (category) ->
  dataCategory = '[data-categories*="' + category + '"]'
  $('.box-schema.active').hide().filter(dataCategory).css("display","inline-block")
  if $('.box-schema.avtice').filter(dataCategory).length == 0
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
