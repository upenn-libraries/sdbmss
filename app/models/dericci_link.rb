class DericciLink < ActiveRecord::Base
  belongs_to :name
  belongs_to :dericci_record

  include UserFields
  include TellBunny

  after_create :watch_this

  def watch_this
    Watch.create(watched: self.dericci_record, user: self.created_by)
    Watch.create(watched: self.name, user: self.created_by)
  end

  def to_rdf
    map = {
      model_class: "dericci_links",
      id: id,
      fields: {}
    }

    map[:fields][:dericci_record_id] = "<https://sdbm.library.upenn.edu/dericci_records/#{dericci_record_id}>" if dericci_record_id.present?
    map[:fields][:name_id]           = "<https://sdbm.library.upenn.edu/names/#{name_id}>"                     if name_id.present?
    map[:fields][:other_info]        = "'''#{other_info}'''"                                                   if other_info.present?

    map
  end

end