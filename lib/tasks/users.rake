namespace :users do
  desc "Grant platform_admin to a user by email: rake users:promote_admin[user@example.com]"
  task :promote_admin, [ :email ] => :environment do |_t, args|
    email = args[:email]

    if email.blank?
      puts "Usage: rake users:promote_admin[user@example.com]"
      next
    end

    user = User.find_by(email: email)

    if user.nil?
      puts "No user found with email #{email}."
      next
    end

    if user.platform_admin?
      puts "#{user.email} is already a platform admin."
      next
    end

    user.update!(platform_admin: true)
    puts "#{user.email} is now a platform admin."
  end

  desc "Revoke platform_admin from a user by email: rake users:demote_admin[user@example.com]"
  task :demote_admin, [ :email ] => :environment do |_t, args|
    email = args[:email]

    if email.blank?
      puts "Usage: rake users:demote_admin[user@example.com]"
      next
    end

    user = User.find_by(email: email)

    if user.nil?
      puts "No user found with email #{email}."
      next
    end

    unless user.platform_admin?
      puts "#{user.email} is not a platform admin."
      next
    end

    user.update!(platform_admin: false)
    puts "#{user.email} is no longer a platform admin."
  rescue ActiveRecord::RecordNotSaved
    puts "FAILED: cannot demote the last platform administrator."
  end
end
