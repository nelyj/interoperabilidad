widthVerbsCollapsed = 85
verbsWidth = 256
windowWidth = 0
urlSourceCode = null
editors = {}

document.addEventListener 'turbolinks:load', ->
  setContainerServicesWidth()
  urlSourceCode = $('#generate-code').attr('href')
  $('.console-parameter-group .raw-json').each (index, element) ->
    location = $(element).closest('.console-parameter-group').data('location')
    editors[location] = ace.edit(element);
    editors[location].$blockScrolling = Infinity
    editors[location].setTheme("ace/theme/monokai");
    editors[location].getSession().setMode("ace/mode/json");
    editors[location].setValue("{}")
  setConsoleBtnOptions('#btns-service-console li a:first')
  cloneObjectsForm()
resizeEditors = ->
  for location, editor of editors
    editor.resize()

paramsFromEditors = ->
  params = {}
  for loc, editor of editors
    params["#{loc}_params"] = JSON.parse(editor.getValue())
  return params

cloneObjectsForm = () ->
  $('.clonable').each (index, element) ->
    clonedElement = $(element).clone()
    $(clonedElement).insertBefore($(element)).addClass('template')

resizeEditors = ->
  for location, editor of editors
    editor.resize()

paramsFromEditors = ->
  params = {}
  for loc, editor of editors
    params["#{loc}_params"] = JSON.parse(editor.getValue())
  return params

$(window).resize ->
  setContainerServicesWidth()

setContainerServicesWidth = () ->
  windowWidth = ( $(window).width() - 1 )
  $(".container-service").css("width", windowWidth - $('.container-verbs').width())
  $(".operation, .console, .container-verbs").css("min-height", $(".wrapper-operation").height())
  $(".container-service").css("min-height", $(".container-verbs").height())

#Verbs Col
$(document).on 'click', '#collapseVerbs', ->
  $('.container-verbs')
    .toggleClass('in')
    .promise().done =>
      unless $('.container-verbs').hasClass('in')
        $('.container-service').width(windowWidth - widthVerbsCollapsed)
      else
        $('.container-service').width(windowWidth - verbsWidth)
        $('.operation')
          .removeClass('out')
          .addClass('in')
        $('.console')
          .removeClass('in full')
          .addClass('out')
        $('.container-service').removeClass('console-full')
        $('.collapseConsole')
          .removeClass('default full')
          .addClass('btn-success')
          .prop('disabled', false)
      resizeEditors()
      return
  return

#Operation - Console Col
$(document).on 'click', '.collapseConsole', ->
  $('.console, .operation')
    .toggleClass('in')
    .promise().done =>
      unless $('.console').hasClass('in')
      else
        $('.container-service').width(windowWidth - widthVerbsCollapsed)
        $('.collapseConsole')
          .removeClass('btn-success')
          .addClass('default full')
          .prop('disabled', true)
        $('.container-verbs').removeClass('in')
      resizeEditors()
      return
  return

$(document).on 'click', '#closeConsole', ->
  $('.console').removeClass('in full')
  $('.collapseConsole')
    .removeClass('default full')
    .addClass('btn-success')
    .prop('disabled', false)
  $('.operation')
    .removeClass('out')
    .addClass('in')
  resizeEditors()

$(document).on 'click', '#fullConsole', ->
  unless $('.console').hasClass('full')
    $('.console').addClass('full')
    $('.container-service').addClass('console-full')
    $('.operation').addClass('out')
  else
    $('.console')
      .removeClass('full')
      .addClass('in')
    $('.container-service').removeClass('console-full')
    $('.operation')
      .removeClass('out')
  resizeEditors()

$(document).on 'change', '#code-options input[type="checkbox"]', ->
  data = $('#code-options').serializeArray()
  languagesParams = data.map (data) -> "languages[]=#{data.name}"
  languages = languagesParams.join('&')
  url = urlSourceCode + '?' + languages
  $("#generate-code").attr("href", url)

$(document).on 'click', '.add-element', ->
  context = $('.console div[data-pointer="' + $(this).data('context') + '"]')
  original = $(context).find('.template')
  cloned = $(context).find('.template').clone()
  value = 0
  $(cloned).find('span.name:first').text("[#{value}]")
  $(cloned)
    .removeClass('template')
    .insertAfter( $(original) )

$(document).on 'click', '.display-tab', (e) ->
  e.preventDefault()
  thisTab = $(this).attr('data-tab')
  parent = $(this).closest('.console-parameter-group')
  $(parent)
    .find('li.active')
    .not(this)
    .removeClass('active');
  $(this).addClass('active');
  $(parent)
    .find('.tab-pane').not($(thisTab))
    .removeClass('active')
  $(parent)
    .find($(thisTab))
    .addClass('active')

setConsoleBtnOptions = (element) ->
  $(element)
    .parents('.btn-group')
    .find('.dropdown-toggle').attr('data-value', $(element).text())
    .html($(element).text() + ' <span class="caret"></span>')

$(document).on 'click', '#btns-service-console li a', () ->
  setConsoleBtnOptions($(this))

$(document).on 'click', '#try-service', ->
  $.ajax(
    method: 'POST'
    contentType: 'application/json'
    data: JSON.stringify(paramsFromEditors()),
  ).done( (data, status, jqxhr) ->
    $('#response').fadeTo(200, 0.1).text(data).fadeTo(200, 1.0)
  ).fail( (jqxhr, status, error) ->
    $('#response').fadeTo(200, 0.1).text("Error: " + status + " " + error).fadeTo(200, 1.0)
  ).always( ->
    hljs.highlightBlock document.getElementById('response')
  )

$(document).on 'change', '#switch_service_select', ->
  targetURL = $(this).val()
  if targetURL
    location.href = targetURL
