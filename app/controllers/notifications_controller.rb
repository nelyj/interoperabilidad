class NotificationsController < ApplicationController
  before_action :set_user, only: [:index, :show]

  def index
    if user_signed_in? && @user.rut == current_user.rut
      @notifications = @user.notifications.all
      @notifications.update_all(seen: true)
    else
      redirect_to root_path, notice: t(:not_enough_permissions)
    end
  end

  def show
    if user_signed_in?
      @notification = @user.notifications.where(id: params[:id]).first
      @notification.mark_as_read
      redirect_to @notification.subject.url
    else
      redirect_to root_path, notice: t(:not_enough_permissions)
    end
  end

  def set_user
    @user = User.where(id: params[:user_id]).first
  end

end
