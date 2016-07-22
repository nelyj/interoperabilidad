class HomeController < ApplicationController
  def root
    redirect_to services_path
  end

  def index
    @featured_services = Service.featured
    @popular_services = Service.popular
  end

  def search
    @text_search = params[:text_search]
    organization = Organization.where(name: @text_search).first
    if organization.blank?
      @services = Service.search(params[:text_search])
    else
      @services = organization.services
    end
  end

  def pending_approval
    @pending_services_version = ServiceVersion.proposed
  end
end
