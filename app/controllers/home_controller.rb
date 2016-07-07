class HomeController < ApplicationController
  def root
    redirect_to services_path
  end

  def index
    @services = Service.all
  end

  def search
    @text_search = params[:text_search]
    @services = Service.search(params[:text_search])
  end

  def pending_approval
    @pending_services_version = ServiceVersion.proposed
  end
end
