require 'digest'

class LoginController < ApplicationController
  def login
    @user = User.find_by_email(params[:email])
    if @user
      if @user.locked_until && Time.now < @user.locked_until
        redirect_to root_url, alert: 'User is locked due to too many missed password attempts. Please try again later.'
      else
        if @user.password == params[:password]
          # successful login attempt
          @user.reset_missed_password_attempts
          log_user_in
          redirect_to protected_url, notice: "Login successful! Hello, #{@user.display_name}!"
        else
          # wrong password
          logger.debug "User is found, wrong password"
          @user.count_missed_password_attempt
          redirect_to root_url, alert: 'Email or password is incorrect.'
        end
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

  def send_email_auth
    @user = User.find_by_email(params[:email])
    if @user
      @token = @user.set_email_auth_token
      # TODO: this logger entry should be deleted in production
      logger.debug("email auth token of user #{@user} is #{@token}")
      UserMailer.mail_authn(@user.email, @token).deliver_now
    end
    # say that mail is sent, even if user with specified address does not exist
    redirect_to root_url, notice: 'Login link is sent to your email address.'
  end

  def email_auth
    token = params[:token]
    @user = User.find_by_email_auth_token(Digest::SHA256.hexdigest(token))
    if @user && Time.now < @user.email_auth_available_until
      log_user_in
      @user.forget_email_auth_token
      redirect_to protected_url, notice: "Login from Email successful. Hello, #{@user.display_name}!"
    else
      redirect_to root_url, alert: 'Invalid token.'
    end
  end

  def send_password_reset
    @user = User.find_by_email(params[:email])
    if @user && Time.now
      @token = @user.set_password_reset_token
      # TODO: this logger entry should be deleted in production
      logger.debug("email auth token of user #{@user} is #{@token}")
      UserMailer.password_reset(@user.email, @token).deliver_now
    end
    # say that mail is sent, even if user with specified address does not exist
    redirect_to root_url, notice: 'Password reset link is sent to your email address.'
  end

  def password_reset
    @token = params[:token]
    @user = User.find_by_password_reset_token(Digest::SHA256.hexdigest(@token))
    if @user && Time.now < @user.password_reset_available_until
      render :password_reset
    else
      redirect_to root_url, alert: 'Invalid token.'
    end
  end

  def do_password_reset
    @token = params[:token]
    @user = User.find_by_password_reset_token(Digest::SHA256.hexdigest(@token))
    if @user && Time.now < @user.password_reset_available_until
      if params[:password] == params[:password_confirmation]
        @user.forget_password_reset_token
        @user.password = params[:password]
        @user.save
        redirect_to root_url, alert: 'Password has been reset. Please login with your new password.'
      else
        flash[:alert] = 'Password inputs did not match.'
        render :password_reset
      end
    else
      redirect_to root_url, alert: 'Invalid token.'
    end
  end

  private
  def log_user_in
    session[:user] = @user
    cookies[:remember_token] = { value: @user.set_remember_token, expires: 2.days }
  end
end
