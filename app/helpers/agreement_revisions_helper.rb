module AgreementRevisionsHelper

  def agreement_allowed_actions
    case @agreement.state
    when 'draft'
      agreement_consumer_validate_actions
    when 'validated_draft'
      agreement_consumer_sign_actions
    when 'objected'
      agreement_objected_actions
    when 'signed_draft'
      agreement_provider_validate_actions
    when 'validated'
      agreement_provider_sign_actions
    end
  end

  def agreement_consumer_validate_actions
    content_tag(:a, t(:edit), class: 'btn btn-default',
      href: new_organization_agreement_agreement_revision_path) +
    content_tag(:a, t(:send_draft), class: 'btn btn-primary',
      href: validation_request_organization_agreement_agreement_revision_path(@consumer_organization, @agreement, @agreement_revision))
  end

  def agreement_consumer_sign_actions
    content_tag(:a, t(:reject), class: 'btn btn-danger',
      "data-target" => "#modalAgreementObjected", "data-toggle" => "modal", :type => "button") +
    content_tag(:a, t(:sign_request), class: 'btn btn-success',
      "data-target" => "#modalAgreementOneTimePassword", "data-toggle" => "modal", :type => "button")
  end

  def agreement_objected_actions
    content_tag(:a, t(:edit), class: 'btn btn-default',
      href: new_organization_agreement_agreement_revision_path)
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
    {
      'draft' => 'static',
      'validated_draft' => 'primary',
      'objected' => 'danger',
      'signed_draft' => 'primary',
      'validated' => 'primary',
      'rejected_sign' => 'danger',
      'signed' => 'success'
    }[status] + ' btn-status' || ''
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
