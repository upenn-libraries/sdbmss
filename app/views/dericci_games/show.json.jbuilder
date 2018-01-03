json.dericci_records @game.dericci_records do |record|
  
  json.(record, :id, :name, :dates, :place, :url, :cards, :size, :other_info, :senate_house)

  json.dericci_links record.dericci_links do |link|
    json.(link, :id, :name_id, :other_info)
  end

  json.comments record.comments.reverse do |comment|
    json.comment sanitize simple_format(comment.comment), tags: %w(code b i br strong em a), attributes: %w(href)
    json.created_by comment.created_by.to_s
    json.created_at comment.created_at.to_formatted_s(:long)
  end

  json.dericci_record_flags record.dericci_record_flags do |flag|
    json.(flag, :id, :reason, :_destroy)
  end

end