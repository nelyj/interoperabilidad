class SchemaVersionsController < ApplicationController

  def show
    set_schema
    @schema_version = SchemaVersion.find(params[:version_number])
    respond_to do |format|
      format.html
    end
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

  def set_schema_version
    @schema_version = SchemaVersion.find(params[:id])
  end

  def set_schema
    @schema = Schema.find_by(name: params[:schema_name])
  end

  def schema_version_params
    params.require(:schema_version).permit(:spec)
  end
end
