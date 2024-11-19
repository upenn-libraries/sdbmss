json.(@model, :id, :name, :viaf_id, :subtype, :startdate, :enddate, :is_author, :is_artist, :is_scribe, :is_provenance_agent, :other_info)

json.name_places @model.name_places.order(:order) do |name_place|
  json.(name_place, :id, :notbefore, :notafter, :order)
  json.place do
    json.(name_place.place, :id, :name)
  end
end