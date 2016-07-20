@widthVerbsCollapsed = 85
@windowWidth = 0
@verbsWidth = 0

document.addEventListener 'turbolinks:load', =>
  @windowWidth = $(window).width()
  @verbsWidth = $('.container-verbs').width()
  $(".container-service").css("min-height", $(".container-verbs").height())
  @urlSourceCode = $("#generate-code").attr("href")

#Verbs Col
$(document).on 'click', '#collapseVerbs', =>
  $('.container-verbs')
    .toggleClass('in')
    .promise().done =>
      unless $('.container-verbs').hasClass('in')
        $('.container-service').width( @windowWidth - @widthVerbsCollapsed )
      else
        $('.container-service').width( @windowWidth - @verbsWidth )
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
      return
  return

#Operation - Console Col
$(document).on 'click', '.collapseConsole', =>
  $('.console, .operation')
    .toggleClass('in')
    .promise().done =>
      unless $('.console').hasClass('in')
        console.log "consola not in"
      else
        console.log "consola in"
        $('.container-service').width( @windowWidth - @widthVerbsCollapsed )
        $('.collapseConsole')
          .removeClass('btn-success')
          .addClass('default full')
          .prop('disabled', true)
        $('.container-verbs').removeClass('in')
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

$(document).on 'change', '#code-options input[type="checkbox"]', =>
  data = $('#code-options').serializeArray()
  @languages = ''
  $.each data, (key, data) =>
    item = if (key == 0) then ('languages[]=' + data.name) else ('&languages[]=' + data.name)
    @languages += item
    return
  url = if @languages then @urlSourceCode + '?' + @languages else @urlSourceCode
  $("#generate-code").attr("href", url)

