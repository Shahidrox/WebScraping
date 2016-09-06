Rails.application.routes.draw do
  
  devise_for :users
  root 'welcome#top_gift_card'
  get 'welcome' => 'welcome#index'
  get 'get_value' => 'welcome#get_value'
  get 'feach_deta' => 'welcome#feach_deta'
  get 'flash_deals' => 'welcome#flash_deals'
  get 'top_gift_card' => 'welcome#top_gift_card'
  
  get 'feach_flash_deals' => 'welcome#feach_flash_deals'
  get 'feach_top_gift_card' => 'welcome#feach_top_gift_card'
  get 'sort_with_rank' => 'welcome#sort_with_rank'
  get 'update_cards' => 'welcome#update_cards'
  get 'search_merchant' => 'welcome#search_merchant'
  get 'get_merchants' => 'welcome#get_merchants'
  get 'get_merchant_data' => 'welcome#get_merchant_data'
  post 'update_seller' => 'welcome#update_seller'
  get 'card_pricing_rules' => 'welcome#card_pricing_rules'
  get 'update_profile' => 'welcome#update_profile'
  post 'update_password' => 'welcome#update_password'
  get 'unavailable_merchant' => 'gift_card_spread#index'
  get 'unavail_merchant' => 'gift_card_spread#merchant_list_d'
  
  get 'pricing_rules/:url' => 'welcome#pricing_rules'
  get 'merchants' => 'welcome#merchants'
  get 'all_cards' => 'gift_card_spread#all_cards'
  get 'sort_with_rank_all' => 'gift_card_spread#sort_with_rank_all'
  # get 'pricing_rules/:name' => 'welcome#pricing_rules'
end
