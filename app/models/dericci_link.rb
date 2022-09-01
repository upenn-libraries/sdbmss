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

    map[:fields][:dericci_record_id] = format_triple_object dericci_record_id, :string
    map[:fields][:name_id]           = format_triple_object name_id,           :uri,   'https://sdbm.library.upenn.edu/names/'
    map[:fields][:other_info]        = format_triple_object other_info,        :string

    map
  end

end