class SchemasController < ApplicationController

  def index
    @schemas = Schema.all
    set_categories
  end

  def new
    @schema = Schema.new
    set_categories
  end

  def create
    @schema = Schema.new(params.require(:schema).permit(:schema_category_id, :name, :spec))
    if @schema.save
      redirect_to [@schema, @schema.schema_versions.first], notice: 'schema was successfully created.'
    else
      flash.now[:error] = "Could not save schema"
      render action: "new"
    end
  end

  def edit
    @schema = Schema.find_by(name: params[:name])
    set_categories
  end

  def update
    @schema = Schema.find_by(name: params[:name])
    if @schema.update(params.require(:schema).permit(:schema_category_id))
      redirect_to schemas_path, notice: 'schema was successfully updated.'
    else
      render :edit
    end
  end

  private

    def set_schema
      @schema = Schema.find(params[:id])
    end

    def set_categories
      @categories = SchemaCategory.all.map { |category| [category.name, category.id] }
    end
end
