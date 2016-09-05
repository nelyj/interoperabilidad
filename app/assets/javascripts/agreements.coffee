document.addEventListener 'turbolinks:load', ->
  providerOrg = getParameterByName('provider_org')
  serviceId = getParameterByName('service_id')
  if providerOrg && serviceId
    setOptionsOnInit(providerOrg, serviceId)

  $('#sign_request').on 'click', ->
    $this = $(this)
    $this.button 'loading'
    setTimeout (->
      $this.button 'reset'
      return
    ), 25000
    return

$(document).on 'keyup change', '.list-filter', ->
  $target = $($(this).data('target'))
  filter = $(this).val()
  if filter == ""
    showRelatedElements()
  else
    $target.find('.row-list').each (index, element) ->
      if $(element).text().toLowerCase().indexOf( filter.toLowerCase() ) != -1 && $(this).is(':visible')
        $(element).show()
      else
        $(element).hide()

$(document).on 'change', '.row-list input[type="checkbox"]', ->
  if $(this).is(':checked')
    $('.services-list').append '<li data-list="' + $(this).val() + '">' + $(this).parent().text() + '</li>'
  else
    $('.services-list li[data-list="' + $(this).val() + '"').remove()
  return

$(document).on 'change', '#agreement_service_provider_organization_id',->
  unless $(this).val()
    $('.content-list .row-list').hide()
  else
    showRelatedElements()

showRelatedElements = () ->
  organizationID = $('#agreement_service_provider_organization_id').val()
  $('.content-list .row-list').each (index, element) =>
    $(element).hide().find('input').attr('checked', false)
    $('.services-list').html('')
    if $(element).attr('data-organization') == organizationID || !organizationID
      $(element).show()

getParameterByName = (name, url) ->
  if !url
    url = window.location.href
  name = name.replace(/[\[\]]/g, '\\$&')
  regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)')
  results = regex.exec(url)
  if !results
    return null
  if !results[2]
    return ''
  decodeURIComponent results[2].replace(/\+/g, ' ')

setOptionsOnInit = (providerOrg, serviceId) =>
  $('#agreement_service_provider_organization_id').val(providerOrg)
  $('.content-list .row-list').each (index, element) =>
    if $(element).attr('data-organization') == providerOrg
      $(element).show()
  $('.list-selector .content-list input[type=checkbox]').each (index, element) =>
    if $(element).val() == serviceId
      $(element).prop('checked', true)
      $('.services-list').append '<li data-list="' + $(element).val() + '">' + $(element).parent().text() + '</li>'
