@widthVerbsCollapsed = 85
@windowWidth = 0
@serviceWidth = 0

document.addEventListener 'turbolinks:load', =>
  @windowWidth = $(window).width()
  @serviceWidth = $('.container-service').width()

#Verbs Col
$(document).on 'click', '#collapseVerbs', =>
  $('.container-verbs')
    .toggleClass('in')
    .promise().done =>
      unless $('.container-verbs').hasClass('in')
        $('.container-service').width( @windowWidth - @widthVerbsCollapsed )
      else
        $('.container-service').width( @serviceWidth )
        $('.operation')
          .removeClass('out')
          .addClass('in')
        $('.console')
          .removeClass('in full')
          .addClass('out')
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
      return
  return

$(document).on 'click', '#closeConsole', ->
  $('.console').removeClass('in full')
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

