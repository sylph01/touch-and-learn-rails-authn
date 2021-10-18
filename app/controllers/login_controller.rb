class LoginController < ApplicationController
  def login
    @user = User.find_by_email(params[:email])
    if @user && @user.password == params[:password]
      session[:user] = @user
      cookies[:remember_token] = { value: @user.set_remember_token, expires: 2.days }
      redirect_to protected_url, notice: "Login successful! Hello, #{@user.display_name}!"
    else
      redirect_to root_url, alert: 'Email or password is incorrect.'
    end
  end

  def logout
    reset_session
    cookies[:remember_token] = nil
    redirect_to root_url, notice: 'Logged out.'
  end
end
