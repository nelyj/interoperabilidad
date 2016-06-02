class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def clave_unica
    @user = User.from_omniauth(request.env["omniauth.auth"])
    sign_in_and_redirect @user, :event => :authentication
    set_flash_message(:notice, :success, :kind => "ClaveUnica") if is_navigational_format?
  end

  def failure
    redirect_to root_path
  end
end
