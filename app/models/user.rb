require 'bcrypt'
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
end
