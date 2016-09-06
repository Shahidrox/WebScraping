require 'rufus-scheduler'
scheduler = Rufus::Scheduler::singleton
# scheduler = Rufus::Scheduler.start_new

scheduler.every '1m' do
	puts "-------------#{Time.now.in_time_zone("Mumbai").strftime("%I:%M %p")}---------------"
end

scheduler.every '23h' do
  puts '----------------------Update seller----------------------'
  WelcomeController.new.update_seller
  puts '----------------------End Update seller----------------------'
end

scheduler.every '10m' do
  puts '----------------------Update Top Cards--------------------------'
  WelcomeController.new.update_cards
  puts '----------------------End Update Top Cards----------------------'
end

# scheduler.every '2h' do
#   puts '----------------------Start Creating All Data--------------------------'
#   WelcomeController.new.update_all_cards
#   puts '----------------------End Creating All Data--------------------------'
# end

scheduler.every '3h' do
  puts '----------------------Start Creating All Data--------------------------'
  WelcomeController.new.schedule_for_card
  puts '----------------------End Creating All Data--------------------------'
end