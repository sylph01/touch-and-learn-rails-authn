class AddLockoutColumnsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :locked_until, :datetime
    add_column :users, :missed_password_attempts, :integer, default: 0
  end
end
