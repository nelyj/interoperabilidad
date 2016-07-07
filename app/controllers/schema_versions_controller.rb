class SchemaVersionsController < ApplicationController

  def show
    set_schema
    @schema_version = @schema.schema_versions.where(version_number: params[:version_number]).take
    respond_to do |format|
      format.html do
        # Fall into view rendering.
      end
      format.json do
        render json: JSON.pretty_generate(@schema_version.spec)
      end
    end
  end

  def index
    set_schema
    @schema_versions = @schema.schema_versions
  end

  def new
    return unless user_signed_in?
    set_schema
    if current_user.can_create_schemas
      @schema_version = SchemaVersion.new
    else
      redirect_to [@schema, @schema.last_version], notice: t(:not_enough_permissions)
    end
  end

  def create
    set_schema
    @schema_version = @schema.schema_versions.new()
    if params[:schema_version].blank?
      flash[:error] = "#{t(:cant_create_schema_version)}: #{t(:must_upload_a_spec_file)}"
      render :new
      return
    end
    @schema_version.update(schema_version_params.merge(user:current_user))
    if @schema_version.save
      redirect_to [@schema, @schema_version], notice: t(:new_schema_version_created)
    else
      flash.now[:error] = t(:cant_create_schema_version)
      render :new
    end
  end

  private

  def schema_version_params
    params.require(:schema_version).permit(:spec_file)
  end

  def set_schema
    @schema = Schema.where(name: params[:schema_name]).take
  end
end
