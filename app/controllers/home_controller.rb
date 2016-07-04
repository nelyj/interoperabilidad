class HomeController < ApplicationController
  def index
    redirect_to schemas_path
  end
end
