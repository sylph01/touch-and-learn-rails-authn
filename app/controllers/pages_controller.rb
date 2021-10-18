class PagesController < ApplicationController
  def root
    render
  end

  def protected
    require_login_user
  end

  private
  def require_login_user
    if !session[:user]
      redirect_to root_url, alert: 'Login required.'
    end
  end
end
