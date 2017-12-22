class AgreementRevision <ApplicationRecord
  include S3Configuration
  include Rails.application.routes.url_helpers
  belongs_to :agreement
  belongs_to :user
  before_create :set_revision_number
  attr_readonly :state

  default_scope -> { order('created_at DESC') }

  # draft: 0, validated_draft: 1, objected: 2, signed_draft:3 , validated:4 , rejected_sign:5, signed:6
  #
  # The lifecycle is handled by methods in the Agreement class. Those methods
  # create a new revision with the next state in the lifecycle — DO NOT change
  # the state of a specific revision in methods of this class. The possible
  # states are the following:
  #
  # 1. The initial agreement revision of a new agreement is born as "draft".
  #
  # 2. Next it is validated by consumer attorney, a new revision with the
  #   state "validated_draft" (See Agreement#validate_draft) is generated. Note
  #   that the attorney can't send the agreement back to the creator. If any
  #   change is required, it has to edit the agreement himself.
  #
  # 3. Then it is reviewed/signed by consumer undersecretary. Here a new revision
  #   with the state "signed_draft" (See Agreement#sign_draft) is created.
  #   Note that the undersecretary can't edit the agreement. If any change is
  #   required it has to object the agreement...
  #
  # 4. ...In which case a new agreement revision is created with the state
  #   "objected" (See Agreement#object_revision) and should be reviewed again by
  #   the attorney (Back to step 2)
  #
  # 5. Back to the happy path, a "signed_draft" from step 3 is then reviewed by
  #    the attorney of the provider organization. If everything looks OK to him,
  #    a new agreement revision will be created with the "validated" state
  #    (See Agreement#validate_revision). If something DOES NOT look OK to him,
  #    he can also object a revision...
  #
  # 6. ...In which case just like in step 4, a new agreement revision is created
  #    with the state  "objected" (See Agreement#object_revision) and the
  #    objections have to be reviewed by the attorney of the consumer (Back to
  #    step 2).
  #
  # 7. Again on the happy path: A "validated" agreement revision has to be
  #    signed by the provider organization's undersecretary, in which case the
  #    final revision of the agreement will be created with the "signed" state.
  #    (See Agreement#sign). But of course the undersecretary might NOT want to
  #    sign it...
  #
  # 8. ...In which case, a new agreement revision is created sith the
  #    "rejected_sign" state (See Agreement#reject_sign). Note that this is a
  #    different state than "objected" because the *provider*'s attorney has to
  #    look at the comments from his undersecretary and either edit/forward them
  #    to his counterpart (the consumer's attorney) or disagree with those
  #    comments and still recommend the agreement to be signed. In other words,
  #    we are back to step 5.
  #
  # ALWAYS add new states at the end.
  enum state: [:draft, :validated_draft, :objected, :signed_draft, :validated, :rejected_sign, :signed]

  def to_param
    revision_number.to_s
  end

  def set_revision_number
    self.revision_number = agreement.last_revision_number + 1
  end

  def upload_pdf(file_name, file_path)
    new_object = codegen_bucket.objects.build(file_name)
    new_object.content = open(file_path)
    new_object.content_type = 'application/pdf'
    new_object.save
    self.update(file: file_name)
  end

  def request_pdf_url
    begin
      object = codegen_bucket.objects.find(self.file)
      object.temporary_url
    rescue => e
      Rollbar.error('For Agreement id:' + self.agreement.id.to_s + ' revision: ' +
        self.revision_number.to_s + ' error whas: ' + e.to_s)
      return ''
    end
  end

  def send_notifications
    notify_responsables
    notify_next_step_responables
  end

  def create_notification_for_user(notify_user, email)
    notify_user.notifications.create(
      subject: self,
      message: I18n.t(:agreement_next_step_responsable_message,
                        id: agreement.id.to_s,
                        log: log,
                        responsable: user.name),
      email: email) unless notify_user.notifications.where(subject: self).exists?
  end

  def notify_responsables
    if self.revision_number > 1
      agreement.agreement_revisions.where("revision_number != ?", self.revision_number).each do |revision|
        create_notification_for_user(revision.user, revision.responsable_email)
      end
    end
  end

  def notify_next_step_responables
    next_step_users = agreement.next_step_responsables
    if !next_step_users.nil?
      next_step_users.each do |responsable|
        responsable[:email].each do |email|
          notify_user = User.where(name: responsable[:name]).first
          create_notification_for_user(notify_user, email) unless notify_user.nil?
        end
      end
    end
  end

  def responsable_email
    if revision_number == 1
      role = user.roles.where(name: "Create Agreement", organization: agreement.service_consumer_organization).first
      return role.email unless role.nil?
    else
      case state
      when 'draft', 'objected','validated_draft', 'signed_draft'
        role = user.roles.where(name: AgreementRevision.state_to_role(state), organization: agreement.service_consumer_organization).first
        return role.email unless role.nil?
      when 'validated', 'rejected_sign', 'signed'
        role = user.roles.where(name: AgreementRevision.state_to_role(state), organization: agreement.service_provider_organization).first
        return role.email unless role.nil?
      end
      return ''
    end
  end

  def url
    organization_agreement_agreement_revision_path(self.agreement.service_consumer_organization, self.agreement, self)
  end

  def self.state_to_role(state)
    case state
    when 'draft', 'validated_draft','objected',  'rejected_sign', 'validated'
      return "Validate Agreement"
    when  'signed', 'signed_draft'
      return "Sign Agreement"
    end
  end

end
