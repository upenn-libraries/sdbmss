module Watchable

  extend ActiveSupport::Concern

  included do
    has_many :watches, as: :watched
    has_many :watchers, through: :watches, source: :user
  end

end