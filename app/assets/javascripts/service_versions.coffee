widthVerbsCollapsed = 85
verbsWidth = 256
windowWidth = 0
urlSourceCode = null
editors = {}

resizeEditors = ->
  for location, editor of editors
    editor.resize()

paramsFromEditors = ->
  params = {}
  for loc, editor of editors
    params["#{loc}_params"] = JSON.parse(editor.getValue())
  return params

document.addEventListener 'turbolinks:load', ->
  setContainerServicesWidth()
  urlSourceCode = $("#generate-code").attr("href")
  $('.console-parameter-group .raw-json').each (index, element) ->
    location = $(element).closest('.console-parameter-group').data('location')
    editors[location] = ace.edit(element);
    editors[location].$blockScrolling = Infinity
    editors[location].setTheme("ace/theme/monokai");
    editors[location].getSession().setMode("ace/mode/json");
    editors[location].setValue("{}")
  setConsoleBtnOptions('#btns-service-console li a:first')

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
        console.log "consola in"
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
  context = $(this).data('context')
  object = $(".console div[data-pointer='#{context}']")
  $(object)
    .first()
    .clone()
    .appendTo(object.parent())

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
  $('#response').text("\u21bb")
  $.ajax(
    method: 'POST'
    contentType: 'application/json'
    data: JSON.stringify(paramsFromEditors()),
  ).done( (data, status, jqxhr) ->
    $('#response').text(data)
  ).fail( (jqxhr, status, error) ->
    $('#response').text("Error: " + status + " " + error)
  ).always( ->
    hljs.highlightBlock document.getElementById('response')
  )
