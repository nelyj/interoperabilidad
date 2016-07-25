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
  convertFormsToJSON()

window.convertFormsToJSON = ->
  $('.console-parameter-group').each (index, paramGroup) ->
    location = $(paramGroup).data('location')
    return unless location
    $formPanelSet = $(paramGroup).find('.schema-panel-set')
    editor = editors[location]
    $formPanelSet.find('input, select').each (index, inputWidget) ->
      $inputWidget = $(inputWidget)
      # Don't process array template elements:
      return if $inputWidget.parents('.clonable').length > 0
      baseTargetPointer = ""
      targetPointer = $inputWidget.closest('.panel-group').attr('data-target')
      propertyType = $inputWidget.attr('type') ||  $inputWidget.data('type')
      propertyValue = $inputWidget.val()
      # Don't set empty optional properties:
      return if propertyValue == "" && !$inputWidget.attr('required')
      return if propertyValue == "" && (inputWidget.tagName == "SELECT" && inputWidget.options[0].value == "")
      switch propertyType
        when "integer"
          propertyValue = parseInt(propertyValue)
        when "number"
          propertyValue = parseFloat(propertyValue)
        when "checkbox", "boolean"
          propertyValue = $inputWidget.is(':checked')
      console.info "SET:"
      console.log targetPointer, propertyValue

resizeEditors = ->
  for location, editor of editors
    editor.resize()

paramsFromEditors = ->
  params = {}
  for loc, editor of editors
    params["#{loc}_params"] = JSON.parse(editor.getValue())
  return params

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

setArrayIndex = (arrayPanelBody, index) ->
  panelGroup = arrayPanelBody.children('.panel-group')
  originalTarget = panelGroup.attr('data-target')
  newTarget = originalTarget.replace(/\/\d+$/, "/#{index}")
  panelGroup.attr('data-target', newTarget)
  panelGroup.children('.panel').children('.panel-heading').find('.name').text("[#{index}]")
  panelGroup.find("[data-target^='#{originalTarget}']").each (index, panelGroupToFix) ->
    $(panelGroupToFix).attr('data-target',
      $(panelGroupToFix).attr('data-target').replace(originalTarget, newTarget)
    )
  panelGroup.find("[data-context^='#{originalTarget}']").each (index, buttonToFix) ->
    $(buttonToFix).attr('data-context',
      $(buttonToFix).attr('data-context').replace(originalTarget, newTarget)
    )

$(document).on 'change', '#code-options input[type="checkbox"]', ->
  data = $('#code-options').serializeArray()
  languagesParams = data.map (data) -> "languages[]=#{data.name}"
  languages = languagesParams.join('&')
  url = urlSourceCode + '?' + languages
  $("#generate-code").attr("href", url)

$(document).on 'click', '.add-element', ->
  context = $(this).closest('[data-target="' + $(this).data('context') + '"]')
  original = $(context).children('.panel').children('.panel-collapse').children('.clonable')
  cloned = original.clone()
  $(cloned)
    .removeClass('clonable').addClass('clone')
    .insertBefore($(this).parent())
  setArrayIndex(cloned, cloned.siblings('.clone').length)

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
    url: location.href,
    method: 'POST'
    contentType: 'application/json'
    data: JSON.stringify(paramsFromEditors()),
  ).done( (data, status, jqxhr) ->
    $('#response').fadeTo(200, 0.1).text(data).fadeTo(200, 1.0)
  ).fail( (jqxhr, status, error) ->
    $('#response').fadeTo(200, 0.1).text("Error: " + status + " " + error).fadeTo(200, 1.0)
  ).always( ->
    $('.console-response-group').show()
    hljs.highlightBlock document.getElementById('response')
  )

$(document).on 'change', '#switch_service_select', ->
  targetURL = $(this).val()
  if targetURL
    location.href = targetURL

$(document).on 'focus', 'form input[type=number]', (e) ->
  $(this).on 'mousewheel.disableScroll', (e) ->
    e.preventDefault()

$(document).on 'blur', 'form input[type=number]', (e) ->
  $(this).off('mousewheel.disableScroll')
