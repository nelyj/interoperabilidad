class SchemaVersionsController < ApplicationController

  def show
    set_schema
    @schema_version = SchemaVersion.find(params[:version_number])
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
    @schema_version = @schema.schema_versions.build(spec: params[:spec_file].read)
    if @schema_version.save
      redirect_to [@schema, @schema_version], notice: 'schema_version was successfully created.'
    else
      render :new
    end
  end

  private

  def set_schema
    @schema = Schema.find_by(name: params[:schema_name])
  end
end
