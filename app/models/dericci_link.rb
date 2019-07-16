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
    {
      model_class: "dericci_links",
      id: id,
      fields: {
        dericci_record_id: "<https://sdbm.library.upenn.edu/dericci_records/#{dericci_record_id}>",
        name_id: "<https://sdbm.library.upenn.edu/names/#{name_id}>",
        other_info: "'''#{other_info}'''"
      }
    }
  end

end