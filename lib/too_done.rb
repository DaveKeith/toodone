require "too_done/version"
require "too_done/init_db"
require "too_done/user"
require "too_done/session"
require "too_done/task"
require "too_done/list"

require "set"
require "date"
require "thor"
require "pry"

module TooDone
  class App < Thor
    def real_date?(year, month, day)
      r1 = false
      r2 = false
      r3 = false
      result = false
      year.between?(2016, 2100)? r1 = true : r1 = false
      thirty_day = Set.new([4, 6, 9, 11])
      month.between?(1, 12)? r2 = true : r2 = false
      if month == 2 && year % 4 == 0
        day < 30? r3 = true : r3 = false
      elsif month == 2 && year % 4 != 0
        day < 29? r3 = true : r3 = false
      elsif thirty_day.include?(month)
        day < 31? r3 = true : r3 = false
      else
        day < 32? r3 = true : r3 = false
      end
      (r1 == true && r2 == true && r3 == true)? result = true : result = false
      result
    end

    desc "add 'TASK'", "Add a TASK to a todo list."
    option :list, :aliases => :l, :default => "*default*",
      :desc => "The todo list which the task will be filed under."
    option :date, :aliases => :d,
      :desc => "A Due Date in YYYY-MM-DD format."
    def add(task)
      puts "Enter user name:"
      user_name = gets.chomp
      puts "Enter the list name in which you want to add this task:"
      list_name = gets.chomp
      TooDone::User.find_or_create_by(name: user_name)
      due_date = "2000-01-01"
      d = Date.parse(due_date)
      while !real_date?(d.year, d.month, d.day)
        puts "Enter the date in which you would like to accomplish this task YYYY-MM-DD format:"
        due_date = gets.chomp
        begin
          d = Date.parse(due_date)
        rescue ArgumentError
        end
      end
      due_date = due_date.to_date
      TooDone::List.find_or_create_by(list_name: list_name,
      user_name: user_name)
      t = TooDone::Task.find_or_create_by(task: task, list_name: list_name,
      due_date: due_date, completed: false)
      list = TooDone::List.find_by(user_name: user_name, list_name: list_name)
      task_count = list.task_count + 1
      list.update(task_count: task_count)
      t
      # find or create the right todo list
      # create a new item under that list, with optional date
    end

    desc "edit", "Edit a task from a todo list."
    option :list, :aliases => :l, :default => "*default*",
      :desc => "The todo list whose tasks will be edited."
    def edit
      puts "Enter the name of the list containing the task you want edit:"
      list_name = gets.chomp
      list = TooDone::List.find(list_name)
      t1 = TooDone::Task.where(list_name: list_name)
      t1.each do |row|
        puts "list name: #{row.list_name}"
        puts "task name: #{row.task}"
        puts "due date: #{row.due_date}"
        puts "completed: #{row.completed}"
      end
      puts "Enter the name of the task you want edit:"
      task = gets.chomp
      t2 = TooDone::Task.find_by(list_name: list_name, task: task)
      puts "do you want to update due date? ('y' for yes)"
      choice1 = gets.chomp.downcase
      if choice1 == "y"
        due_date = "2000-01-01"
        d = Date.parse(due_date)
        while !real_date?(d.year, d.month, d.day)
          puts "Enter the date in YYYY-MM-DD format:"
          due_date = gets.chomp
          begin
            d = Date.parse(due_date)
          rescue ArgumentError
          end
        end
        t2.update(due_date: due_date)
      end
      puts "do you want to update the task name? ('y' for yes)"
      choice2 = gets.chomp.downcase
      if choice2 == "y"
        puts "enter task name:"
        task = gets.chomp
        t2.update(task: task)
      end
      puts
      puts "list name: #{t2.list_name}"
      puts "task name: #{t2.task}"
      puts "due date: #{t2.due_date}"
      puts "completed: #{t2.completed}"
      # find the right todo list
      # BAIL if it doesn't exist and have tasks
      # display the tasks and prompt for which one to edit
      # allow the user to change the title, due date
    end

    desc "done", "Mark a task as completed."
    option :list, :aliases => :l, :default => "*default*",
      :desc => "The todo list whose tasks will be completed."
    def done
      puts "Enter the name of the list containing the task you have completed:"
      list_name = gets.chomp
      list = TooDone::List.find_by(list_name: list_name)
      t1 = TooDone::Task.where(list_name: list_name)
      t1.each do |row|
        puts
        puts "list id: #{row.id}"
        puts "list name: #{row.list_name}"
        puts "task name: #{row.task}"
      end
      puts "enter the ID of the completed task:"
      id = gets.chomp.to_i
      t2 = TooDone::Task.find_by(id: id)
      t2.update(completed: true)
      list.update(task_count: list.task_count - 1)
      puts
      t2
      # find the right todo list
      # BAIL if it doesn't exist and have tasks
      # display the tasks and prompt for which one(s?) to mark done
    end

    desc "show", "Show the tasks on a todo list in reverse order."
    option :list, :aliases => :l, :default => "*default*",
      :desc => "The todo list whose tasks will be shown."
    option :completed, :aliases => :c, :default => false, :type => :boolean,
      :desc => "Whether or not to show already completed tasks."
    option :sort, :aliases => :s, :enum => ['history', 'overdue'],
      :desc => "Sorting by 'history' (chronological) or 'overdue'.
      \t\t\t\t\tLimits results to those with a due date."
    def show
      puts "Enter the list name in which you want to display:"
      list_name = gets.chomp
      list = TooDone::List.find_or_create_by(list_name: list_name)
      puts "Display in reverse order? ('y' for yes)"
      choice = gets.chomp.downcase
      tasks = TooDone::Task.where(list_name: list_name).order(id: :asc)
      if choice == 'y'
        tasks = TooDone::Task.where(list_name: list_name).order(id: :desc)
      end
      tasks
      # find or create the right todo list
      # show the tasks ordered as requested, default to reverse order (recently entered first)
    end

    desc "delete [LIST OR USER]", "Delete a todo list or a user."
    option :list, :aliases => :l, :default => "*default*",
      :desc => "The todo list which will be deleted (including items)."
    option :user, :aliases => :u,
      :desc => "The user which will be deleted (including lists and items)."
    def delete
      puts "Do you want to delete a list? ('y' for yes)"
      choice1 = gets.chomp.downcase
      if choice1 == "y"
        puts "Enter the list name in which you want to delete:"
        list_name = gets.chomp
        list = TooDone::List.find_by(list_name: list_name)
        list.destroy
        tasks = TooDone::Task.where(list_name: list_name)
        tasks.each do |t|
          t.destroy
        end
      end
      puts "Do you want to delete a user? ('y' for yes)"
      choice2 = gets.chomp.downcase
      if choice2 == "y"
        puts "Enter the user name in which you want to delete:"
        user_name = gets.chomp
        user = TooDone::User.find_by(name: user_name)
        user.destroy
        lists = TooDone::List.where(user_name: user_name)
        lists.each do |l|
          l.destroy
        end
      end
      # BAIL if both list and user options are provided
      # BAIL if neither list or user option is provided
      # find the matching user or list
      # BAIL if the user or list couldn't be found
      # delete them (and any dependents)
    end

    desc "switch USER", "Switch session to manage USER's todo lists."
    def switch(username)
      user = User.find_or_create_by(name: username)
      user.sessions.create
    end

    private
    def current_user
      Session.last.user
    end
  end
end

binding.pry
TooDone::App.start(ARGV)
