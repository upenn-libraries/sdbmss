module Watchable

  extend ActiveSupport::Concern

  included do
    has_many :watches, as: :watched, dependent: :destroy
    has_many :watchers, through: :watches, source: :user
  end

end