class CreateTasks < ActiveRecord::Migration
  def up
    create_table :tasks do |t|
      t.string :task, null: false
      t.string :list_name, null: false
      t.datetime :due_date
      t.boolean :completed, default: false
    end
  end

  def down
    drop_table :users
  end
end
