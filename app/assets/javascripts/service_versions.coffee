widthVerbsCollapsed = 85
windowWidth = 0
verbsWidth = 0
urlSourceCode = null
editors = {}

resizeEditors = ->
  for location, editor of editors
    editor.resize()

document.addEventListener 'turbolinks:load', ->
  windowWidth = $(window).width()
  verbsWidth = $('.container-verbs').width()
  $(".container-service").css("min-height", $(".container-verbs").height())
  urlSourceCode = $("#generate-code").attr("href")
  $('.console-parameter-group .raw-json').each (index, element) ->
    section = $(element).closest('.console-parameter-group').data('location')
    editors[location] = ace.edit(element);
    editors[location].setTheme("ace/theme/monokai");
    editors[location].getSession().setMode("ace/mode/json");
    editors[location].setValue("{}")

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
        console.log "consola not in"
      else
        console.log "consola in"
        $('.container-service').width(windowWidth - widthVerbsCollapsed )
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
    $('.operation').addClass('out')
  else
    $('.console')
      .removeClass('full')
      .addClass('in')
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
