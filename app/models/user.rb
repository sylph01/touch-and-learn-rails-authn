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
end
