require 'bcrypt'
require 'securerandom'
require 'digest'
class User < ApplicationRecord
  include BCrypt

  validates :email, presence: true
  validates :password_digest, presence: true

  def password
    @password ||= Password.new(password_digest)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_digest = @password
  end

  def set_remember_token
    @token = SecureRandom.alphanumeric(64)
    self.remember_token = Digest::SHA256.hexdigest(@token)
    self.remember_token_valid_until = Time.now + 1.day
    save
    @token
  end

  def forget_remember_token
    self.remember_token = nil
    self.remember_token_valid_until = nil
    save
  end

  def set_email_auth_token
    @token = SecureRandom.alphanumeric(64)
    self.email_auth_token = Digest::SHA256.hexdigest(@token)
    self.email_auth_available_until = Time.now + 30.minutes
    save
    @token
  end

  def forget_email_auth_token
    self.email_auth_token = nil
    self.email_auth_available_until = nil
    save
  end

  def count_missed_password_attempt
    self.missed_password_attempts = self.missed_password_attempts + 1
    logger.debug("[count_missed_password_attempt] User #{self.id} missed #{self.missed_password_attempts} attempts")
    save
    set_lockout_period
  end

  def reset_missed_password_attempts
    self.locked_until = nil
    self.missed_password_attempts = 0
    save
  end

  private
  def set_lockout_period
    self.locked_until = Time.now + (2 ** (missed_password_attempts - 1)).seconds
    logger.debug("[set_lockout_period] User #{self.id} is locked until #{self.locked_until}")
    save
  end
end
