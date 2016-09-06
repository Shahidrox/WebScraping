class WelcomeController < ApplicationController
  
  def index
    @merchants= Merchant.order("max_savings DESC").page(params[:page]).per(15)
  end
  
  def feach_deta
  end
  
  def get_value
    url = URI("http://partners.giftcardgranny.com/api/merchants")
    http = Net::HTTP.new(url.host, url.port)
    request = Net::HTTP::Get.new(url)
    request["authorization"] = 'Basic ZXJpYy5iZXJnZXJAY2FyZGNhc2guY29tOmFiY2dpZnRjYXJkczEyMTU='
    response = http.request(request)
    data = JSON.parse(response.body)
    data.each do |k|
      @merchant = Merchant.find_by_name(k['name'])
      if @merchant.present?
        @merchant.update(ecodes_available: k['ecodes_available'], max_savings: k['max_savings'], average_savings: k['average_savings'], cards_available: k['cards_available'])
      else
        Merchant.create(name: k['name'], granny_url: k['granny_url'], website: k['website'], ecodes_available: k['ecodes_available'], max_savings: k['max_savings'], average_savings: k['average_savings'], cards_available: k['cards_available'])
      end
    end

    render :json => {:msg => data}
  end
  
  def flash_deals
  end
  
  def top_gift_card
    @card_time= (Card.last.present?) ? Card.last.updated_at : nil
  end
  
  def feach_flash_deals
    url = URI("https://api.giftcardgranny.com/flashDeals/")
    data = commen_method(url)
    render :json => {:msg => data}
  end
  
  def feach_top_gift_card
    card_creat_date = CardDetail.last
    if card_creat_date.present? && card_creat_date.created_at.strftime("%Y-%m-%d") == Time.now.utc.strftime("%Y-%m-%d")
      @card = Card.where(card_detail_id: card_creat_date.id, card_type: 'Gift Card', value: 0..24.99).order('merchant')
    else
      new_card_list = CardDetail.create(day: Date.today.strftime("%A"))
      update_cards
      @card = Card.where(card_detail_id: new_card_list.id, card_type: 'Gift Card').order('merchant')
    end
    
    merchant_name = @card.uniq.pluck(:merchant)
    @card_arr = []
    merchant_name.each do |f|
      march_obj = @card.where(merchant: f).order('value DESC')
      march_obj.each_with_index do |v, index|
        @card_arr << {rank: v.rank, merchant: v.merchant, card_type: v.card_type, quantity: v.quantity, value: v.value, discount: v.discount, one_and_one: v.one_and_one, one_and_gcs: v.one_and_gcs, seller: v.seller, v_rank: index+1 }
      end
    end
    @card_arr = @card_arr.sort_by {|e| [e[:merchant], e[:rank]] }
  end
  
  def update_cards
    card_avl = CardDetail.last
    card_creat_date = (card_avl.present?)? card_avl.id : ''
    url = URI("https://api.giftcardgranny.com/cards/")
    data = commen_method(url)
    merchant = data.map{|t| t['merchant']['name']}.uniq
    merchant = merchant.sort! { |a,b| a.downcase <=> b.downcase}
    # gif_card_list = []
    # e_card_list = []
    Card.delete_all
    merchant.each do |f|
      obj = data.select { |c| c['merchant']['name'].include?(f) }
      gift_card = obj.select { |x| x['type'] == 'Gift Card' }
      e_card = obj.select { |x| x['type'] == 'eCode' }
      gcs_gift = gift_card.select { |c| c['partner']['name'].include?('Gift Card Spread') }
      gcs_e = e_card.select { |c| c['partner']['name'].include?('Gift Card Spread') }
      if gcs_gift.present?
        gift_card.delete_if{|t| t['partner']['name'] == 'eBay'}
        create_top_giftcard(gift_card.to_a, card_creat_date)
      end
      if gcs_e.present?
        e_card.delete_if{|t| t['partner']['name'] == 'eBay'}
        create_top_giftcard(e_card.to_a, card_creat_date)
      end
    end
    # if gif_card_list.present?
    #   create_top_giftcard(gif_card_list, card_creat_date)
    # end 
    # if e_card_list.present?
    #   create_top_giftcard(e_card_list, card_creat_date)
    # end 
    
  end
  
  def create_top_giftcard(gift_card, card_creat_date)
    
    range1 = sort_topcard(gift_card, 1, 24.99)
    range2 = sort_topcard(gift_card, 25, 49.99)
    range3 = sort_topcard(gift_card, 50, 99.99)
    range4 = sort_topcard(gift_card, 100, 249.99)
    range5 = sort_topcard(gift_card, 250, 99999)
    if range1.present?
      uniq_gift = filter_top_gift_card(range1)
      creat_card_with_rank(uniq_gift, card_creat_date)
    end
    if range2.present?
      uniq_gift = filter_top_gift_card(range2)
      creat_card_with_rank(uniq_gift, card_creat_date)
    end
    if range3.present?
      uniq_gift = filter_top_gift_card(range3)
      creat_card_with_rank(uniq_gift, card_creat_date)
    end
    if range4.present?
      uniq_gift = filter_top_gift_card(range4)
      creat_card_with_rank(uniq_gift, card_creat_date)
    end
    if range5.present?
      uniq_gift = filter_top_gift_card(range5)
      creat_card_with_rank(uniq_gift, card_creat_date)
    end
  end
  
  def sort_topcard(arr, range1, range2)
    if arr.present?
      arr.select {|e| e['value'].to_i.between?(range1, range2)}
    else
      []
    end
  end
  
  def filter_top_gift_card(gift_card)
    gift_card.uniq{|t| t['partner']['name']}
  end
  
  
  
  def creat_card_with_rank(arr, card_creat_date)
    csd = arr.select { |c| c['partner']['name'].include?('Gift Card Spread') }
    if csd.present?
      ActiveRecord::Base.transaction do
        arr.each_with_index do |l, index|
          obj1 = (arr.first.present?) ? arr.first['save_percent'].to_f : 0.0
          obj2 = (arr.second.present?)? arr.second['save_percent'].to_f : obj1
          # csd = arr.select{ |d| d['partner']['name'].include?('Gift Card Spread') }
          gcs_dis = (csd.present?) ? obj1 - csd.first['save_percent'].to_f : 0.0
          discount_diff = obj1 - obj2
          Card.create(card_detail_id: card_creat_date, rank: index+1, merchant: l['merchant']['name'], card_type: l['type'], quantity: l['quantity'], value: l['value'], discount: l['save_percent'], seller: l['partner']['name'].to_s, one_and_one: discount_diff, one_and_gcs: gcs_dis)
        end
      end
    end  
  end
  
  def sort_with_rank
    card_creat_id = CardDetail.last.id
    
    if to_bool(params['physical']) and !to_bool(params['ecode'])
      card_ty = 'Gift Card'
    elsif !to_bool(params['physical']) and to_bool(params['ecode'])
      card_ty = 'eCode'
    else
      card_ty = ['eCode','Gift Card']
    end
    
    if params[:price_rule].present?
      if params[:price_rule].to_i == 1
        range = 0..24.99
      elsif params[:price_rule].to_i == 2
        range = 25..49.99
      elsif params[:price_rule].to_i == 3
        range = 50..99.99
      elsif params[:price_rule].to_i == 4
        range = 100..249.99
      elsif params[:price_rule].to_i == 5
        range = 250..999999999
      elsif params[:price_rule].to_i == 6
        range = 0..999999999  
      end
    else
      range = 0..999999999
    end

    if params[:rank] == 'Sort Rank'
      @card = Card.where(card_detail_id: card_creat_id, card_type: card_ty, value: range)#.order(sort).order('merchant')
    else
      @card = Card.where(card_detail_id: card_creat_id, rank: params[:rank], seller: 'Gift Card Spread', card_type: card_ty, value: range)#.order(sort).order('rank')
    end
    merchant_name = @card.uniq.pluck(:merchant)
    @card_arr = []
    merchant_name.each do |f|
      march_obj = @card.where(merchant: f).order('value DESC')
      march_obj.each_with_index do |v, index|
        @card_arr << {rank: v.rank, merchant: v.merchant, card_type: v.card_type, quantity: v.quantity, value: v.value, discount: v.discount, one_and_one: v.one_and_one, one_and_gcs: v.one_and_gcs, seller: v.seller, v_rank: index+1 }
      end
    end

    if params[:price_rule].to_i == 6
      merchant_name.each do |f|
        obj = @card_arr.select{|x| x[:merchant] == f}
        march_obj1 = obj.sort_by {|e| [-e[:discount]] }
        march_obj1.each_with_index do |v, index|
          v[:rank] = index+1
        end
      end
    end  
    
    sorting_parms = params[:sort]
    if sorting_parms.present?
      if sorting_parms == 'ASC'
        @card_arr = @card_arr.sort_by {|e| [e[:merchant], e[:rank]] } if params[:byname] == 'merchant'
        @card_arr = @card_arr.sort_by { |h| h[:discount] } if params[:byname] == 'discount'
        @card_arr = @card_arr.sort_by { |h| h[:one_and_one] } if params[:byname] == 'one_and_one'
        @card_arr = @card_arr.sort_by { |h| h[:one_and_gcs] } if params[:byname] == 'one_and_gcs'
      elsif sorting_parms == 'DESC'
        @card_arr = @card_arr.reverse! if params[:byname] == 'merchant'
        @card_arr = @card_arr.sort_by { |h| -h[:discount]} if params[:byname] == 'discount'
        @card_arr = @card_arr.sort_by { |h| -h[:one_and_one]} if params[:byname] == 'one_and_one'
        @card_arr = @card_arr.sort_by { |h| -h[:one_and_gcs]} if params[:byname] == 'one_and_gcs'
      end
    else
      @card_arr = @card_arr.sort_by {|e| [e[:merchant], e[:rank]] }
    end
  end
  
  def update_seller
    url = URI("https://api.giftcardgranny.com/partners/")
    data = commen_method(url)
    @seller = Seller.last
    if @seller.present?
      unless @seller.updated_at.strftime("%Y-%m-%d") != Time.now.utc.strftime("%Y-%m-%d")
        data.each do |s|
          sl = Seller.find_by_seller_id(s['id'])
          if !sl.present?
            Seller.create(seller_id: s['id'], seller_name: s['name'])
          end
        end
      end
    else
      data.each do |s|
        Seller.create(seller_id: s['id'], seller_name: s['name'])
      end
    end
    # render :json => {:msg => data}
  end
  
  def search_merchant
    get_merchants
  end
  
  def pricing_rules
    get_merchants
  end
  
  def get_merchants
    url = URI("https://api.giftcardgranny.com/merchants/")
    cards = []
    commen_method(url).each do |m|
      cards.push(m['name'])
    end
    @data = cards
  end
  
  def get_merchant_data
    key = params[:key]
    url = URI("https://www.giftcardgranny.com/buy-gift-cards/#{key}/?getCards=1")
    data = commen_method(url)
    byname = data.uniq{|x| x['nId']}
    mrg = []
    byname.each do |sn|
      seller_name = Seller.find_by_seller_id(sn['nId']).seller_name
      mrg << sn.merge!(sN: seller_name)
    end
    render :json => {:msg => mrg}
  end
  
  
  
  def card_pricing_rules
    key = params[:key]
    url = URI("https://www.giftcardgranny.com/buy-gift-cards/#{key}/?getCards=1")
    discountCards_url = "https://www.giftcardgranny.com/buy-gift-cards/#{key}/"
    doc = Nokogiri::HTML(open(discountCards_url))
    
    arr_obj1 = (doc.present?) ? doc.css('script')[5] : []
    arr_obj2 = (arr_obj1.present?) ? arr_obj1.text.split(";")[1] : []
    arr_obj = (arr_obj2.present?) ? arr_obj2.split("=")[1] : []
    begin
      top_20 = (arr_obj.present?)? JSON.parse(arr_obj) : []
    rescue
      top_20 = []
    end
    
    
    all_rco = commen_method(url) + top_20
    if to_bool(params['physical']) and !to_bool(params['ecode'])
      all_rco = all_rco.select {|e| e['ty'] == 'physical'}
    elsif !to_bool(params['physical']) and to_bool(params['ecode'])
      all_rco = all_rco.select {|e| e['ty'] == 'ecode'}
    end

    sort_with_range(all_rco, params['range1'], params['range2'], params['range3'], params['range4'], params['range5'], params['range6'])
    if @grand.blank?
      @grand = all_rco
    end
    
    data_arr = []
    @grand.each do |sn|
      slr = Seller.find_by_seller_id(sn['nId'])
      seller_name = (slr.present?) ? slr.seller_name : 'Not Available'
      data_arr << sn.merge!(sN: seller_name) if seller_name != 'eBay'
    end
    
    if params[:price_rule].present?
      if params[:price_rule].to_i == 1
        str = 0
        nd = 24.99
      elsif params[:price_rule].to_i == 2
        str = 25
        nd = 49.99
      elsif params[:price_rule].to_i == 3
        str = 50
        nd = 99.99
      elsif params[:price_rule].to_i == 4
        str = 100
        nd = 249.99
      elsif params[:price_rule].to_i == 5
        str = 250
        nd = 999999999
      end
    else
      str = 0
      nd = 999999999
    end
    
    data_arr_1 = data_arr.select {|e| e['va'].between?(str, nd)}
    
    sort_for_vrank = data_arr_1.uniq{ |x| x[:sN]}
    gcs_cards = sort_for_vrank.select {|e| e[:sN] == 'Gift Card Spread' }
    v_1 = (sort_for_vrank[0].present?)? sort_for_vrank[0]['sP'] : 0
    v_2 = (sort_for_vrank[1].present?)? sort_for_vrank[1]['sP'] : 0
    v_gcs = (gcs_cards[0].present?) ? gcs_cards[0]['sP'] : 0
    one_2_dif = v_1 - v_2
    gcs_1_dif = v_1 - v_gcs
    
    sort_for_vrank = sort_for_vrank.sort_by {|e| -e['va'] }
    v_rank = []
    rnk = 0
    sort_for_vrank.each do |v|
      rnk = rnk + 1
      one_2 = (v[:sN] == 'Gift Card Spread')? one_2_dif.round(2) : ''
      one_gcs = (v[:sN] == 'Gift Card Spread')? gcs_1_dif.round(2) : ''
      v_rank << v.merge!(vRank: rnk, oneTwo:one_2, oneGcs:one_gcs)
    end

    v_rank = v_rank.sort_by {|e| -e['sP'] }
    
    render :json => {:msg => v_rank}
  end
  
  def commen_method(url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(url)
    response = http.request(request)
    begin
      JSON.parse(response.body)
    rescue
      []
    end
  end
  
  def to_bool(key)
    return true if key == 'true'
    return false if key == 'false'
  end
  
  def sort_with_range(arr, r1, r2, r3, r4, r5, all)
    range1 = []
    if to_bool(r1)
      range1 = arr.select {|e| e['va'].between?(1, 24.99)}
    end
    range2 = []
    if to_bool(r2)
      range2 = arr.select {|e| e['va'].between?(25, 49.99)}
    end
    range3 = []
    if to_bool(r3)
      range3 = arr.select {|e| e['va'].between?(50, 99.99)}
    end
    
    range4 = []
    if to_bool(r4)
      range4 = arr.select {|e| e['va'].between?(100, 249.99)}
    end
    
    range5 = []
    if to_bool(r5)
      range5 = arr.select {|e| e['va'].between?(250, 99999)}
    end
    @grand = range1 + range2 + range3 + range4 + range5
  end
  
  def update_profile
  end
  
  def update_password
    @user = User.find(current_user.id)
    if @user.update(update_password_params)
      flash[:notice] = "password updated successfully"
    else
      flash[:notice] = "something's wrong. please try again"
    end
    redirect_to root_path
  end
  
  def merchants
  end
  
  def update_all_cards
    gcs_merchant_list = GiftCardSpreadController.new.merchant_list_d
    puts "merchant reloded: #{gcs_merchant_list.count}"
    gcs_merchant_list.each do |m|
      AllCard.delete_all(merchant: m[:m])
      url = URI("https://www.giftcardgranny.com/buy-gift-cards/#{m[:v]}/?getCards=1")
      discountCards_url = "https://www.giftcardgranny.com/buy-gift-cards/#{m[:v]}/"
      # remote_ip = "%d.%d.%d.%d" % [rand(256), rand(256), rand(256), rand(256)]
      puts '==================================='
      puts request
      puts '==================================='
      begin
        doc = Nokogiri::HTML(open(discountCards_url))
        arr_obj = doc.css('script')[5]#.split(";")[1].split("=")[1]
        arr_obj = (arr_obj.present?) ? arr_obj.text : []
        arr_obj = (arr_obj.present?) ? arr_obj.split(";")[1] : []
        arr_obj = (arr_obj.present?) ? arr_obj.split("=")[1] : []
        top_20 = (arr_obj.present?)? JSON.parse(arr_obj) : []
      rescue
        top_20 = []
      end
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(url)
      response = http.request(request)
      begin
        data = JSON.parse(response.body)
      rescue
        data = []
        puts '---------------------------------------'
        puts response.body
        puts '---------------------------------------'
      end
      all_rco = data + top_20
      if all_rco.present?
        gift_card = all_rco.select { |x| x['ty'] == 'physical' }
        e_card = all_rco.select { |x| x['ty'] == 'ecode' }
        
        if gift_card.present?
          range1 = sort_with_pricing(gift_card, 1, 24.99)
          range2 = sort_with_pricing(gift_card, 25, 49.99)
          range3 = sort_with_pricing(gift_card, 50, 99.99)
          range4 = sort_with_pricing(gift_card, 100, 249.99)
          range5 = sort_with_pricing(gift_card, 250, 99999)
          
          if range1.present?
            uniq_gift = filter_gift_card(range1)
            create_all_gft_card(uniq_gift, m)
          end
          if range2.present?
            uniq_gift = filter_gift_card(range2)
            create_all_gft_card(uniq_gift, m)
          end
          if range3.present?
            uniq_gift = filter_gift_card(range3)
            create_all_gft_card(uniq_gift, m)
          end
          if range4.present?
            uniq_gift = filter_gift_card(range4)
            create_all_gft_card(uniq_gift, m)
          end
          if range5.present?
            uniq_gift = filter_gift_card(range5)
            create_all_gft_card(uniq_gift, m)
          end
        end  
        
        if e_card.present?
          range1 = sort_with_pricing(e_card, 1, 24.99)
          range2 = sort_with_pricing(e_card, 25, 49.99)
          range3 = sort_with_pricing(e_card, 50, 99.99)
          range4 = sort_with_pricing(e_card, 100, 249.99)
          range5 = sort_with_pricing(e_card, 250, 99999)

          if range1.present?
            uniq_gift = filter_gift_card(range1)
            create_all_gft_card(uniq_gift, m)
          end
          if range2.present?
            uniq_gift = filter_gift_card(range2)
            create_all_gft_card(uniq_gift, m)
          end
          if range3.present?
            uniq_gift = filter_gift_card(range3)
            create_all_gft_card(uniq_gift, m)
          end
          if range4.present?
            uniq_gift = filter_gift_card(range4)
            create_all_gft_card(uniq_gift, m)
          end
          if range5.present?
            uniq_gift = filter_gift_card(range5)
            create_all_gft_card(uniq_gift, m)
          end
        end 
        
      end
      sleep 10
    end
    puts AllCard.count
  end

  def schedule_for_card
    gcs_merchant_list = GiftCardSpreadController.new.merchant_list_d
    puts "merchant reloded: #{gcs_merchant_list.count}"
    gcs_merchant_list.each do |m|
      AllCard.delete_all(merchant: m[:m])
      discountCards_url = "https://giftcardtest.herokuapp.com/scrap_api?name=#{m[:v]}"
      # discountCards_url = "https://giftcardgranny-shahidrox.c9users.io/scrap_api?name=#{m[:v]}"
      scra_card = Nokogiri::HTML(open(discountCards_url))
      all_rco = JSON.parse(scra_card)
      puts '---------------------------------------'
      puts "card: #{all_rco.count}"
      puts '---------------------------------------'
      if all_rco.present?
        gift_card = all_rco.select { |x| x['ty'] == 'physical' }
        e_card = all_rco.select { |x| x['ty'] == 'ecode' }
        
        if gift_card.present?
          range1 = sort_with_pricing(gift_card, 1, 24.99)
          range2 = sort_with_pricing(gift_card, 25, 49.99)
          range3 = sort_with_pricing(gift_card, 50, 99.99)
          range4 = sort_with_pricing(gift_card, 100, 249.99)
          range5 = sort_with_pricing(gift_card, 250, 99999)
          
          if range1.present?
            uniq_gift = filter_gift_card(range1)
            create_all_gft_card(uniq_gift, m)
          end
          if range2.present?
            uniq_gift = filter_gift_card(range2)
            create_all_gft_card(uniq_gift, m)
          end
          if range3.present?
            uniq_gift = filter_gift_card(range3)
            create_all_gft_card(uniq_gift, m)
          end
          if range4.present?
            uniq_gift = filter_gift_card(range4)
            create_all_gft_card(uniq_gift, m)
          end
          if range5.present?
            uniq_gift = filter_gift_card(range5)
            create_all_gft_card(uniq_gift, m)
          end
        end  
        
        if e_card.present?
          range1 = sort_with_pricing(e_card, 1, 24.99)
          range2 = sort_with_pricing(e_card, 25, 49.99)
          range3 = sort_with_pricing(e_card, 50, 99.99)
          range4 = sort_with_pricing(e_card, 100, 249.99)
          range5 = sort_with_pricing(e_card, 250, 99999)

          if range1.present?
            uniq_gift = filter_gift_card(range1)
            create_all_gft_card(uniq_gift, m)
          end
          if range2.present?
            uniq_gift = filter_gift_card(range2)
            create_all_gft_card(uniq_gift, m)
          end
          if range3.present?
            uniq_gift = filter_gift_card(range3)
            create_all_gft_card(uniq_gift, m)
          end
          if range4.present?
            uniq_gift = filter_gift_card(range4)
            create_all_gft_card(uniq_gift, m)
          end
          if range5.present?
            uniq_gift = filter_gift_card(range5)
            create_all_gft_card(uniq_gift, m)
          end
        end 
        
      end
      sleep 10
    end
    puts AllCard.count
  end
  
  def filter_gift_card(gift_card)
    uniq_gift = gift_card.uniq{ |x| x['nId']}
    uniq_gift.delete_if{|t| t['nId'] == 2}
    uniq_gift = uniq_gift.sort_by {|e| e['sP'] }.reverse
    uniq_gift
  end
  
  def sort_with_pricing(arr, range1, range2)
    arr.select {|e| e['va'].between?(range1, range2)}
  end
  
  def create_all_gft_card(card_arr, m)
    ec_csd = card_arr.select{ |d| d['nId'] == 28 }
    if ec_csd.present?
      ec_obj1 = (card_arr.first.present?) ? card_arr.first['sP'].to_f : 0.0
      ec_obj2 = (card_arr.second.present?)? card_arr.second['sP'].to_f : ec_obj1
      ec_discount_diff = ec_obj1 - ec_obj2
      ec_gcs_dis = (ec_csd.present?) ? ec_obj1 - ec_csd.first['sP'].to_f : 0.0
      ActiveRecord::Base.transaction do
        card_arr.each_with_index do |n, index|
          slr = Seller.find_by_seller_id(n['nId'])
          seller_name = (slr.present?) ? slr.seller_name : 'Not Available'
          AllCard.create(rank: index+1,card_type: n['ty'], discount: n['sP'], value: n['va'],quantity: n['qu'], seller: seller_name, merchant:m[:m], one_and_one: ec_discount_diff, one_and_gcs: ec_gcs_dis)
        end
      end
    end  
  end
  
  private
  
  def update_password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
  
end
