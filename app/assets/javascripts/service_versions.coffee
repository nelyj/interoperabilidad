@widthVerbsCollapse = 85;
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
        $('.container-service').width( @windowWidth - @widthVerbsCollapse )
      else
        $('.container-service').width( @serviceWidth )
      return
  return

#Operation - Console Col
$(document).on 'click', '.collapseConsole', =>
  $('.console, .operation')
    .toggleClass('in')
    .promise().done =>
      unless $('.console').hasClass('in')
        console.log "consola not in"
        #$('.container-service').width( @windowWidth - @widthVerbsCollapse )
      else
        console.log "consola in"
        #$('.container-service').width( @serviceWidth )
      return
  return

$(document).on 'click', '#closeConsole', ->
  $('.console').removeClass('in')
  $('.console').removeClass('full')
  $('.operation').removeClass('out')
  $('.operation').addClass('in')

$(document).on 'click', '#fullConsole', ->
  unless $('.console').hasClass('full')
    $('.operation, .console').removeClass('in')
    $('.operation').addClass('out')
    $('.console').addClass('full')
    $('.operation').addClass('out')
  else
    $('.console').removeClass('full')
    $('.console').addClass('in')
    $('.operation').removeClass('out')




