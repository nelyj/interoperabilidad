class SchemasController < ApplicationController

  def index
    @categories = SchemaCategory.all
    @schemas = Schema.all
  end

  def new
    return unless user_signed_in?
    if current_user.can_create_schemas
      @schema = Schema.new
      @categories = SchemaCategory.all
    else
      redirect_to schemas_path, notice: 'no tiene permisos suficientes'
    end
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
    return unless user_signed_in?
    if current_user.can_create_schemas
      set_schema
    else
      redirect_to schemas_path, notice: 'no tiene permisos suficientes'
    end
  end

  def update
    set_schema
    if @schema.update(params.require(:schema).permit(:schema_category_id))
      redirect_to schemas_path, notice: 'schema was successfully updated.'
    else
      render :edit
    end
  end

  def search
    @text_search = params[:text_search]
    @schemas = Schema.search(params[:text_search])
  end

  private

  def schema_params
    params.require(:schema).permit(:schema_category_id, :name, :spec_file)
  end

  def set_schema
    @schema = Schema.where(name: params[:name]).take
  end
end
