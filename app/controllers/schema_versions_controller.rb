class SchemaVersionsController < ApplicationController

  def show
    set_schema
    @schema_version = SchemaVersion.where(version_number: params[:version_number]).take
    @same_category_schemas = @schema_version.schema.schema_category.schemas
  end

  def index
    set_schema
    @schema_versions = @schema.schema_versions
  end

  def new
    @schema_version = SchemaVersion.new
    set_schema
  end

  def create
    set_schema
    @schema_version = @schema.schema_versions.build(schema_version_params)
    if @schema_version.save
      redirect_to [@schema, @schema_version], notice: 'schema_version was successfully created.'
    else
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
