class DericciRecordFlag < ActiveRecord::Base
  belongs_to :dericci_record

  include UserFields

  def self.reasons
    ["The names or information contained are not relevant or applicable to names in the SDBM", "The name described here should be added to the SDBM Name Authority"]
  end
end
