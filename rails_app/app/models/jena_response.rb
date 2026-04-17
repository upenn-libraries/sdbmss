class JenaResponse < ApplicationRecord
  belongs_to :record, polymorphic: true

#  validates_presence_of :record
end