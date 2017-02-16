json.dericci_records @game.dericci_records do |record|
  
  json.(record, :id, :name, :dates, :place, :url, :cards, :size, :other_info, :senate_house)

  json.dericci_links record.dericci_links do |link|
    if link.created_by == current_user
      json.(link, :id, :name_id, :other_info)
    end
  end

end