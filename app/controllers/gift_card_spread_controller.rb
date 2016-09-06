class GiftCardSpreadController < ApplicationController
  
  def index
    @data = nil
  end
  
  def merchant_list_d
    # url = 'https://www.giftcardspread.com/Images/tempImages/gcs_feed.xml'
    # xml_data = Net::HTTP.get_response(URI.parse(url)).body
    # doc = REXML::Document.new(xml_data)
    # merchant_list = []
    # doc.elements.each('xml_feed/merchant_list/merchant') do |ele|
    #   id = ele.attributes['id']
    #   name = ele.elements['name'].text
    #   sell_Percent = ele.elements['sell_Percent'].text
    #   merchant_list << {id: id, m: name, sell_Percent: sell_Percent}
    # end
    # gift_card_list = []
    # doc.elements.each('xml_feed/gift_card_list/gift_card') do |ele|
    #   id = ele.elements["merchants"].elements['merchant'].text
    #   gift_card_list << id
    # end
    # gift_card_ids = gift_card_list.uniq{|x| x}
    # merchant_data = gift_card_ids.inject([]){|res, val| res << merchant_list.detect {|u| u[:id] == val}}
    url = 'https://www.giftcardspread.com/xmlData/gcs_listed_cards.xml'
    xml_data = Net::HTTP.get_response(URI.parse(url)).body
    doc = REXML::Document.new(xml_data)
    merchant_list = []
    doc.elements.each('listed_cards/card') do |ele|
      id = ele.attributes['id']
      merchant_id = ele.elements['MerchantId'].text
      merchant = ele.elements['Merchant'].text
      seller_name = ele.elements['SellerName'].text
      delivery_type = ele.elements['DeliveryType'].text
      card_value = ele.elements['CardValue'].text
      buy_price = ele.elements['BuyPrice'].text
      listed_card_from = ele.elements['ListedCardFrom'].text
      merchant_list << {id: id, merchant_id: merchant_id, m: merchant, seller_name: seller_name, delivery_type: delivery_type, card_value: card_value, buy_price: buy_price, listed_card_from: listed_card_from}
    end
    merchant_data = merchant_list.uniq{|x| x[:m]}
    add_url = []   
    # merchant_data.each do |c|
    #   obj = MERCHANT.find{|x| x[:m] == c[:m]}
    #   if obj.present?
    #     add_url << c.merge(obj)
    #   else
    #     puts c[:m]
    #     add_url << c.merge({v: ''})
    #   end 
    # end
    merchant_data.each do |c|
      c[:m] = name_setting(c[:m])
      val_url = c[:m].downcase.tr(" ", "-").delete("'").gsub("&", "and")
      add_url << c.merge({v: val_url})
    end
    @data = add_url
  end
  
  def name_setting(m)
    if m == 'BedandBreakfast.com'
      m = 'BedandBreakfast'
    elsif m == 'Bass (G.H bass & Company)'
      m = 'bass'
    elsif m == 'Bob Evans'
      m = 'bob-evans-restaurants'
    elsif m == "BOJangles'"
      m = 'bo-jangles'
    elsif m == 'Gamestop'
      m = 'game-stop'
    elsif m == 'H&M'
      m = 'h-and-m'
    elsif m == 'iTunes'
      m = 'i-tunes'
    elsif m == 'HP'
      m = 'hewlett-packard'  
    elsif m == 'Mastercard'
      m = 'master-card'
    elsif m == 'PacSun'
      m = 'pac-sun'
    elsif m == 'Rue 21'
      m = 'rue21'
    elsif m == 'Pandora'
      m = 'pandora-jewelry'
    elsif m == 'Lucy Activwear'
      m = 'lucy-activewear'
    elsif m == 'Firehouse  Subs'
      m = 'firehouse-subs'
    elsif m == ''
      m = ''  
    end
    m
  end
  
  def all_cards
    @card = AllCard.where(card_type: 'physical', value: 1..24.99)#.order('merchant').order('rank')
    merchant_name = @card.pluck(:merchant).uniq
    @card_a = []
    merchant_name.each do |f|
      march_obj = @card.where(merchant: f).order('value DESC')
      march_obj.each_with_index do |v, index|
        @card_a << {rank: v.rank, merchant: v.merchant, card_type: v.card_type, quantity: v.quantity, value: v.value, discount: v.discount, one_and_one: v.one_and_one, one_and_gcs: v.one_and_gcs, seller: v.seller, v_rank: index+1, created_at: v.created_at }
      end
    end
    @card_arr = @card_a.sort_by {|e| [e[:merchant], e[:rank]] }
  end

  def sort_with_rank_all
    if to_bool(params['physical']) and !to_bool(params['ecode'])
      card_ty = 'physical'
    elsif !to_bool(params['physical']) and to_bool(params['ecode'])
      card_ty = 'ecode'
    else
      card_ty = ['ecode','physical']
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
    if params[:rank].present? and params[:rank] != 'Sort Rank'
      @card = AllCard.where(rank: params[:rank], seller: 'Gift Card Spread', card_type: card_ty, value: range).order('merchant').order('rank')
    else
      @card = AllCard.where(card_type: card_ty, value: range).order('merchant').order('rank')
    end
    merchant_name = @card.pluck(:merchant).uniq
    @card_arr = []
    merchant_name.each do |f|
      march_obj = @card.where(merchant: f).order('value DESC')
      march_obj.each_with_index do |v, index|
        @card_arr << {rank: v.rank, merchant: v.merchant, card_type: v.card_type, quantity: v.quantity, value: v.value, discount: v.discount, one_and_one: v.one_and_one, one_and_gcs: v.one_and_gcs, seller: v.seller, v_rank: index+1, created_at: v.created_at }
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
    # @card_arr = @card_arr.sort_by {|e| [e[:merchant], e[:rank]] }
  end

  def to_bool(key)
    return true if key == 'true'
    return false if key == 'false'
  end
end