class Reply < ActiveRecord::Base
  belongs_to :comment

  include UserFields
  include Notified

  def preview
    %(
      <blockquote>#{reply.at(0..100)}#{reply.length > 100 ? '...' : ''}</blockquote>
    )
  end

end
