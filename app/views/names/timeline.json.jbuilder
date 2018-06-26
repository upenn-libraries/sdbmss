json.title do
  json.text do
    json.text "This is a timeline of all the <b>explicitly dated</b> instances where this name appears in a provenance chain.<br>For <b>#{@model.name}</b>, #{@dated_provenance.count} out of #{@model.provenance_count} total provenance #{'use'.pluralize(@model.provenance_count)} have explicit date information."
  end
end

if @dated_provenance.count > 0
  json.events @dated_provenance do |provenance|
    #json.text do
    #  json.text render partial: "entries/preview", locals: {record: provenance.entry}, :formats => [:html]
    #end
    json.text do
      json.text "#{link_to(provenance.entry.public_id, entry_path(provenance.entry))}"
    end

    year, month, day = provenance.start_date_normalized_start.split("-")
    json.start_date do
      json.year year.to_i
      json.month month.to_i unless month.nil?
      json.day day.to_i unless day.nil?
    end

    json.group provenance.entry.source.source_type.display_name

    if provenance.end_date_normalized_end.present?
      year, month, day = provenance.end_date_normalized_end.split("-")
      json.end_date do
        json.year year.to_i
        json.month month.to_i unless month.nil?
        json.day day.to_i unless day.nil?
      end
    end
  end
else
  json.events [1] do |i|
    json.start_date do
      json.year 0
    end
    json.text do
      json.text "<p class='text-muted'>This name does not have any associated provenance date information that can be computationally processed.</p>"
    end
  end
end