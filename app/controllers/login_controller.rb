class LoginController < ApplicationController
  def login
    @user = User.find_by_email(params[:email])
    if @user && @user.password == params[:password]
      session[:user] = @user
      redirect_to protected_url, notice: "Login successful! Hello, #{@user.display_name}!"
    else
      redirect_to root_url, alert: 'Email or password is incorrect.'
    end
  end
end
