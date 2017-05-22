class DericciLink < ActiveRecord::Base
  belongs_to :name
  belongs_to :dericci_record

  include UserFields

  after_create :watch_this

  def watch_this
    Watch.create(watched: self.dericci_record, user: self.created_by)
    Watch.create(watched: self.name, user: self.created_by)
  end

end