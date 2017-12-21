class DataCategoriesController < ApplicationController
  before_action :check_services_admin

  def index
  end

  def new
    @data_category = DataCategory.new
  end

  def create  
    @data_category = DataCategory.new(data_category_params)
    if @data_category.save
      redirect_to data_categories_path, notice: t(:record_created)
    else
      flash.now[:error] = t(:couldnt_save_record)
      redirect_to data_categories_path
    end
  end

  def edit
    @data_category = DataCategory.find(params[:id])
  end

  def update
    @data_category = DataCategory.find(params[:id])
    if @data_category.update!(data_category_params)
      flash[:success] = I18n.t(:data_category_update_success)
      redirect_to data_categories_path
    else
      flash[:error] = I18n.t(:data_category_update_error)
      redirect_to data_categories_path
    end
  end

  def destroy
    if DataCategory.find(params[:id]).destroy
      flash[:success] = I18n.t(:data_category_deletion_success)
      redirect_to data_categories_path
    else
      flash[:error] = I18n.t(:data_category_deletion_error)
      redirect_to data_categories_path
    end
  end

  private
  def data_category_params
    params.require(:data_category).permit(:name)
  end

  def check_service_admin
    unless user_signed_in? && current_user.is_service_admin?
      redirect_to services_path, notice: t(:cant_manage_data_categories)
    end
  end

end
