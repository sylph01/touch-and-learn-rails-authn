class LoginController < ApplicationController
  def login
    @user = User.find_by_email(params[:email])
    if @user
      if @user.password == params[:password]
        if @user.locked_until && Time.now < @user.locked_until
          redirect_to root_url, alert: 'User is locked due to too many missed password attempts. Please try again later.'
        else
          # successful login attempt
          @user.reset_missed_password_attempts
          session[:user] = @user
          cookies[:remember_token] = { value: @user.set_remember_token, expires: 2.days }
          redirect_to protected_url, notice: "Login successful! Hello, #{@user.display_name}!"
        end
      else
        # wrong password
        logger.debug "User is found, wrong password"
        @user.count_missed_password_attempt
        redirect_to root_url, alert: 'Email or password is incorrect.'
      end
    else
      # user cannot be found
      redirect_to root_url, alert: 'Email or password is incorrect.'
    end
  end

  def logout
    reset_session
    cookies[:remember_token] = nil
    redirect_to root_url, notice: 'Logged out.'
  end
end
