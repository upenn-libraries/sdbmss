class DericciLink < ActiveRecord::Base
  belongs_to :name
  belongs_to :dericci_record

  include UserFields

  after_create :watch_this

  def watch_this
    Watch.create(watched: self.dericci_record, user: self.created_by)
    Watch.create(watched: self.name, user: self.created_by)
    if DericciLink.where(dericci_record: self.dericci_record, name: self.name).sum(:reliability) >= 4
      Set.new(self.dericci_record.watchers + self.name.watchers).to_a.each do |watcher|
        watcher.notify("The link between #{self.dericci_record.public_id} and #{self.name.public_id} has been confirmed as reliable", self.dericci_record, "update")
      end
    end
  end

end