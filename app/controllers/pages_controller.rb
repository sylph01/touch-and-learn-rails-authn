require 'digest'

class PagesController < ApplicationController
  before_action :remember, :set_active_user

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

  def remember
    if !session[:user] && cookies[:remember_token]
      @user = User.find_by_remember_token(Digest::SHA256.hexdigest(cookies[:remember_token]))
      if @user
        if Time.now < @user.remember_token_valid_until
          # log in user
          session[:user] = @user
          # then display flash
          flash[:notice] = "Welcome back, #{@user.display_name}!"
        else
          # invalidate token by forgetting the value
          @user.forget_remember_token
        end
      end
    end
  end

  def set_active_user
    if session[:user]
      @active_user = User.find(session[:user]["id"])
    end
  end
end
