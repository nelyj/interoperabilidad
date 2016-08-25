module AgreementRevisionsHelper

  def agreement_allowed_actions
    case @agreement_revision.state
    when 'draft'
      agreement_request_actions +
      agreement_validate_actions
    when 'validated_draft'
      agreement_sign_actions
    when 'signed_draft'
      ''
    end
  end

  def agreement_request_actions
    content_tag(:button, t(:edit), class: 'btn btn-default') +
    content_tag(:a, t(:send_draft), class: 'btn btn-primary',
      href: request_validation_organization_agreement_agreement_revision_path(@consumer_organization, @agreement, @agreement_revision))
  end

  def agreement_validate_actions
    content_tag(:button, t(:edit), class: 'btn btn-default') +
    content_tag(:button, t(:request_signature),{:controller => :agreement_revisions,
      :action => 'request_validation'}, class: 'btn btn-primary')
  end

  def agreement_sign_actions
    content_tag(:button, t(:reject), class: 'btn btn-danger') +
    content_tag(:button, t(:sign_request), class: 'btn btn-success')
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

end
