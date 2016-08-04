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
     if @agreement.save
      @agreement_revision = @agreement.create_first_revision(current_user)
      redirect_to(
        agreement_agreement_revision_path(@agreement, revision_number: @agreement_revision.revision_number),
        notice: t(:new_agreement_created)
      )
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
