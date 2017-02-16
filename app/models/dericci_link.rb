class DericciLink < ActiveRecord::Base
  belongs_to :name
  belongs_to :dericci_record

#  has_many :comments, as: :commentable

  include UserFields

#  validates_uniqueness_of :name_id, :scope => :dericci_record_id

=begin
  after_create :create_structured_comment
  
  private

  def create_structured_comment
    Comment.create(comment: "This name is linked to <a href='#{dericci_record.url}'>THIS DERICCI CARD</a>", created_by: created_by, commentable: name)
  end
=end

end