class AddRememberTokenToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :remember_token, :string
    add_column :users, :remember_token_valid_until, :datetime
  end
end
