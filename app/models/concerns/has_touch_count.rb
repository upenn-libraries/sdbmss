
# To be included on models that have a 'touch_count' field which is
# incremented on every update; this forces PaperTrail to create a
# Version for an model object even if it didn't change, so that there
# is a way to grab transactions that may contain changes to its
# associations
#
# TODO: unfortunately, this always touches the Entry object even if
# none of its fields (or the fields in any associations) have
# changed. I don't know a good way to avoid this.
module HasTouchCount

  extend ActiveSupport::Concern

  included do
    # it's important that we use before_save and NOT before_update,
    # because ActiveRecord won't auto-update the 'updated_at' field if
    # you change fields using the latter.
    before_save :increment_touch_count
  end

  def increment_touch_count
    self.touch_count = (self.touch_count || 0) + 1
  end

end
