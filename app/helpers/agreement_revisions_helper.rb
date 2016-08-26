module AgreementRevisionsHelper

  def agreement_allowed_actions
    case @agreement_revision.state
    when 'draft'
      agreement_consumer_validate_actions
    when 'validated_draft'
      agreement_sign_actions
    when 'objected'
      agreement_objected_actions
    when 'signed_draft'
      agreement_provider_validate_actions
    end
  end

  def agreement_consumer_validate_actions
    content_tag(:a, t(:edit), class: 'btn btn-default',
      href: new_organization_agreement_agreement_revision_path) +
    content_tag(:a, t(:send_draft), class: 'btn btn-primary',
      href: validation_request_organization_agreement_agreement_revision_path(@consumer_organization, @agreement, @agreement_revision))
  end

  def agreement_sign_actions
    content_tag(:a, t(:reject), class: 'btn btn-danger',
      "data-target" => "#modalAgreementObjected", "data-toggle" => "modal", :type => "button") +
    content_tag(:a, t(:sign_request), class: 'btn btn-success',
      href: consumer_signature_organization_agreement_agreement_revision_path(@consumer_organization, @agreement, @agreement_revision))
  end

  def agreement_objected_actions
    content_tag(:a, t(:edit), class: 'btn btn-default',
      href: new_organization_agreement_agreement_revision_path)
  end

  def agreement_provider_validate_actions
    content_tag(:a, t(:reject), class: 'btn btn-danger',
      "data-target" => "#modalAgreementObjected", "data-toggle" => "modal", :type => "button") +
    content_tag(:a, t(:send_draft), class: 'btn btn-primary',
      href: document_validation_organization_agreement_agreement_revision_path(@consumer_organization, @agreement, @agreement_revision))
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

  def current_active_organization
    if %w(draft validated_draft objected).include?(@agreement_revision.state)
      @consumer_organization
    else
      @provider_organization
    end
  end

end
