class AddPasswordResetColumnsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :password_reset_token, :string
    add_column :users, :password_reset_available_until, :datetime
  end
end
