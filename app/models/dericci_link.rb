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
    %Q(
      sdbm:dericci_links/#{id}
      a       sdbm:dericci_links
      sdbm:dericci_links_dericci_record_id #{dericci_record_id}
      sdbm:dericci_links_id #{id}
      sdbm:dericci_links_name_id #{name_id}
      sdbm:dericci_links_other_info #{other_info}
    )
    #  rdfs:label "dericci_links #1" ;
    
  end

end