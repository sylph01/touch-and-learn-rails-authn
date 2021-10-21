class UserMailer < ApplicationMailer
  def mail_authn(email, token)
    @url = "http://localhost:3000/email_auth?token=#{token}"
    mail(to: email, subject: 'Email authentication')
  end

  def password_reset(email, token)
    @url = "http://localhost:3000/password_reset?token=#{token}"
    mail(to: email, subject: 'Password reset')
  end
end
