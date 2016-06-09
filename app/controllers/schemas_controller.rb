class SchemasController < ApplicationController

  def index
    @schemas = Schema.all
  end

  def new
    @schema = Schema.new
  end

  def create
    @schema = Schema.new(schema_params)
    if @schema.save
      redirect_to [@schema, @schema.schema_versions.first], notice: 'schema was successfully created.'
    else
      flash.now[:error] = "Could not save schema"
      render action: "new"
    end
  end

  def edit
    set_schema
  end

  def update
    set_schema
    if @schema.update(params.require(:schema).permit(:schema_category_id))
      redirect_to schemas_path, notice: 'schema was successfully updated.'
    else
      render :edit
    end
  end

  private

  def schema_params
    params.require(:schema).permit(:schema_category_id, :name, :spec_file)
  end

  def set_schema
    @schema = Schema.find_by(name: params[:name])
  end
end
