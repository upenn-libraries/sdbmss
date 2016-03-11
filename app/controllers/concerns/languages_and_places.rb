
# Languages and Places are almost identical, so we factor out some of
# the controller methods in common here.
module LanguagesAndPlaces

  extend ActiveSupport::Concern

  def search_query_base
    model_class.all.includes([:created_by])
  end

  def search_result_format(obj)
    {
      id: obj.id,
      name: obj.name,
      entries_count: obj.entries_count,
      reviewed: obj.reviewed,
      created_by: obj.created_by.present? ? obj.created_by.username : "(none)",
      created_at: obj.created_at.present? ? obj.created_at.to_formatted_s(:short) : "",
      updated_by: obj.updated_by.present? ? obj.updated_by.username : "(none)",
      updated_at: obj.updated_at.present? ? obj.updated_at.to_formatted_s(:short) : ""
    }
  end

end
