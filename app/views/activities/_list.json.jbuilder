json.activities @details do |(date, users)|
  
  json.date date
  json.activities users.map { |u, list| 
    [User.find(u).username, list.map { |transaction_id, version|
      activity = @activities.select { |a| a.transaction_id == transaction_id }.first
      link_text = SDBMSS::IDS.get_public_id_for_model(activity.item_type, activity.item_id)
      if !link_text
        link_text = "#{activity.item_type} ##{activity.item_id}"
      end
      if activity.event != 'destroy'
        link_text = "<a href='/#{activity.item_type.pluralize.underscore}/#{activity.item_id}' target='_blank'>#{link_text}</a>"
      else
        link_text = "<span class='text-danger'>#{link_text}</span>"
      end
      link_text += "<small class='pull-right'>#{activity.created_at.to_formatted_s(:long)}</small>"

      ["#{activity.format_event} #{link_text}", version[:details]] 
    }.to_h] 
  }.to_h

end