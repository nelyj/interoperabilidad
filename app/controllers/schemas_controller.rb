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
      redirect_to schemas_path, notice: t(:not_enough_permissions)
    end
  end

  def create
    @schema = Schema.new(schema_params)
    if @schema.save
      @schema.create_first_version(current_user)
      @schema.set_data_categories(params[:schema][:data_category_ids])
      redirect_to [@schema, @schema.schema_versions.first], notice: t(:new_schema_created)
    else
      flash.now[:error] = t(:cant_create_schema)
      render action: "new"
    end
  end

  def search
    @text_search = params[:text_search]
    @schemas = Schema.search(params[:text_search])
  end

  private

  def schema_params
    params.require(:schema).permit(:schema_category_ids, :name, :spec_file, :data_category_ids, 'data_category_ids')
  end

  def set_schema
    @schema = Schema.where(name: params[:name]).take
  end
end
