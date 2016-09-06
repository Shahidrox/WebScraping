# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
if User.all.count == 0
    User.create! :email => 'admin@giftcardspread.com', :password => '~=@admin', :password_confirmation => '~=@admin'
    puts 'SETTING UP DEFAULT USER LOGIN'
end