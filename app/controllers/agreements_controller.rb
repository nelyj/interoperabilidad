class AgreementsController < ApplicationController
  before_action :set_organization

  def index
    @agreements = Agreement.all
  end

  def show
  end

  def new
    @agreement = Agreement.new
  end

  def create
    @agreement = Agreement.new(agreement_params)
    @agreement.service_consumer_organization_id = @organization.id
    if @agreement.save
      @agreement.create_first_revision(current_user)
      redirect_to(agreements_path)
    else
      flash.now[:error] = t(:cant_create_agreement)
      render action: "new"
    end
  end

  def edit
  end

private

  def agreement_params
    params.require(:agreement).permit(:service_provider_organization_id,
      :service_consumer_organization_id, :purpose, :legal_base, :services => [])
  end

  def set_organization
      @organization = Organization.where(name: params[:organization_name]).first
  end
end
