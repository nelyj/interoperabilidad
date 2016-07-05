class SchemaVersionsController < ApplicationController

  def show
    set_schema
    @schema_version = @schema.schema_versions.where(version_number: params[:version_number]).take
    respond_to do |format|
      format.html do
        @same_category_schemas = @schema.schema_category.schemas
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
      redirect_to [@schema, @schema.last_version], notice: 'no tiene permisos suficientes'
    end
  end

  def create
    set_schema
    @schema_version = @schema.schema_versions.new()
    @schema_version.update(schema_version_params.merge(user:current_user)) unless params[:schema_version].blank?
    if @schema_version.save
      redirect_to [@schema, @schema_version], notice: 'Nueva versión creada correctamente'
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
