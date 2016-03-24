class CreateToDoList < ActiveRecord::Migration
  def up
    create_table :lists do |t|
      t.string :list_name, null: false
      t.string :user_name, null: false
      # t.integer :task_count, default: 0
    end
  end

  def down
    drop_table :users
  end
end
