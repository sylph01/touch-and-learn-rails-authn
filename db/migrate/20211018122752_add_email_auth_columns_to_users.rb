class AddEmailAuthColumnsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :email_auth_token, :string
    add_column :users, :email_auth_available_until, :datetime
  end
end
