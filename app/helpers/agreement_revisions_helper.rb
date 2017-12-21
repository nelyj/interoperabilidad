module AgreementRevisionsHelper

  def agreement_consumer_sign_actions
    content_tag(:a, t(:reject), class: 'btn btn-danger',
      "data-target" => "#modalAgreementObjected", "data-toggle" => "modal", :type => "button") +
    content_tag(:a, t(:sign_request), class: 'btn btn-success',
      "data-target" => "#modalAgreementOneTimePassword", "data-toggle" => "modal", :type => "button")
  end

  def agreement_provider_validate_actions
    content_tag(:a, t(:reject), class: 'btn btn-danger',
      "data-target" => "#modalAgreementObjected", "data-toggle" => "modal", :type => "button")
  end

  def agreement_provider_sign_actions
    content_tag(:a, t(:reject), class: 'btn btn-danger',
      "data-target" => "#modalAgreementObjected", "data-toggle" => "modal", :type => "button") +
    content_tag(:a, t(:sign_request), class: 'btn btn-success',
      "data-target" => "#modalAgreementOneTimePassword", "data-toggle" => "modal", :type => "button")
  end

  def css_class_for_agreement_status(status)
    'btn-status ' + ({
      'draft' => 'static',
      'validated_draft' => 'primary',
      'objected' => 'danger',
      'signed_draft' => 'primary',
      'validated' => 'primary',
      'rejected_sign' => 'danger',
      'signed' => 'success'
    }[status] || '')
  end

  def buttons_assets
    {
      'draft' => [t(:edit), 'btn btn-default', t(:send_draft), 'btn btn-primary'],
      'objected' => [t(:edit), 'btn btn-default'],
      'signed_draft' => [t(:request_signature), 'btn btn-primary'],
      'rejected_sign' => [t(:send_draft), 'btn btn-primary']
    }[@agreement.state] || []
  end

  def modals_assets
    {
      'validated_draft' => agreement_consumer_sign_actions,
      'signed_draft' => agreement_provider_validate_actions,
      'validated' => agreement_provider_sign_actions,
      'rejected_sign' => agreement_provider_validate_actions
    }[@agreement.state] || ''
  end

end
