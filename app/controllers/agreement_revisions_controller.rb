class AgreementRevisionsController < ApplicationController

  def index
  end

  def show
    @agreement = Agreement.find(params[:agreement_id])
    @agreement_revision = @agreement.agreement_revisions.where(revision_number: params[:revision_number]).first
    @provider_organization = Organization.find(@agreement.service_provider_organization_id)
    @consumer_organization = Organization.find(@agreement.service_consumer_organization_id)
    respond_to do |format|
      format.html
      format.pdf do
        render  :pdf => 'report',
                :template => 'agreement_revisions/template.html.haml',
                :assigns => { agreement: @agreement },
                :save_to_file => Rails.root.join('tmp', "#{@agreement.id}.pdf")
      end
    end
  end

  def new
  end

  def create
  end

  def edit
  end
end
