class ServiceVersionsController < ApplicationController
  before_action :set_organization
  before_action :set_service
  before_action :set_service_version, only: [:show, :source_code, :state, :reject, :try]

  def show
    respond_to do |format|
      format.json { render :json => JSON.pretty_generate(@service_version.spec) }
      format.html do
        if params[:verb].nil?
          default_verb, default_path = @service_version.operations.keys.first
          redirect_to operation_organization_service_service_version_path(
            path: default_path, verb: default_verb
          )
          return
        end
        @verb = params[:verb]
        @path =  params[:path] || '/'
        @operation = @service_version.operation(@verb, @path)
        if @operation.nil?
          # Rails removes trailing slashes from URLs
          # https://github.com/rails/journey/issues/17
          # If the path had a trailing slash, we wouldn't find the operation
          # so lets try again adding a slash before giving up
          @operation = @service_version.operation(@verb, @path + '/')
          if @operation.nil?
            render status: :not_found
            return
          else
            @path = @path + '/'
          end

        end
        # Fall into view rendering
      end
    end
  end

  def index
    @service_versions = @service.service_versions.order('version_number DESC')
  end

  def new
    return unless user_signed_in?
    if @service.can_be_updated_by?(current_user)
       @service_version = ServiceVersion.new
    else
      redirect_to(
        organization_service_service_versions_path(
          @organization, @service
          ),
        notice: t(:not_enough_permissions)
      )
    end
  end

  def create
    if params[:service_version].blank?
      flash[:error] = "#{t(:cant_create_service_version)}: #{t(:must_upload_a_spec_file)}"
      redirect_to organization_service_service_versions_path(@organization, @service)
      return
    end
    @service_version = @service.service_versions.build(service_version_params)
    @service_version.user = current_user
    if @service_version.save
      redirect_to [@organization, @service, @service_version], notice: t(:new_service_version_created)
    else
      render :new
    end
  end

  def source_code
    default_langs = %w(java php csharp jaxrs-cxf slim aspnet5)
    redirect_to @service_version.generate_zipped_code(
      params[:languages] || default_langs
    )
  end

  def try
    additional_headers = {}
    if !@service_version.service.public && user_signed_in?
      if current_user.can_try_protected_service?(@service_version.service)
        additional_headers['Autentication'] = "Bearer #{@service_version.service.generate_client_token}"
      end
    end
    render plain: @service_version.invoke(
      params[:verb],
      params[:path] || '/',
      params[:path_params].try(:to_unsafe_h) || {},
      params[:query_params].try(:to_unsafe_h) || {},
      (params[:header_params].try(:to_unsafe_h) || {}).merge!(additional_headers),
      params[:body_params].try(:to_unsafe_h)
    ).to_s
  rescue Exception => e
    render plain: (t(:error_while_invoking_service) + ":\n\t" +  e.to_s)
  end

  def reject
    if user_signed_in? && current_user.is_service_admin?
      @service_version.update(reject_message: params[:service_version][:reject_message])
      reject_version
    else
      redirect_to(
        organization_service_service_versions_path(
          @organization, @service, @service_version
          ),
        notice: t(:not_enough_permissions)
      )
    end
  end

  def state
    if user_signed_in? && current_user.is_service_admin?
      new_state = params[:state]
      case new_state
      when 'current'
        make_current_version
      when 'rejected'
        reject_version
      else
        Rollbar.error('For ' + self.service.name + ' version ' +
          self.version_number + ' the new_state was: ' + new_state)
      end
    else
      redirect_to(
        organization_service_service_versions_path(
          @organization, @service, @service_version
          ),
        notice: t(:not_enough_permissions)
      )
    end
  end

  def make_current_version
    set_service_version
    @service_version.make_current_version
    redirect_to pending_approval_services_path
  end

  def reject_version
    set_service_version
    @service_version.reject_version
    redirect_to pending_approval_services_path
  end

  private

  def service_version_params
    params.require(:service_version).permit(:spec_file, :backwards_compatible)
  end

  def set_service
    @service = @organization.services.where(name: params[:service_name]).first
  end

  def set_organization
    @organization = Organization.where(name: params[:organization_name]).first
  end

  def set_service_version
    @service_version = @service.service_versions.where(version_number: params[:version_number]).first
  end
end
