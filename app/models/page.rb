class Page < ActiveRecord::Base
  validates :name, uniqueness: true, presence: true
  validates :filename, uniqueness: true, presence: true

  def ext
    filename.split('.').last
  end

  def location
    if category == 'tooltip'
      'static/tooltips'
    else
      'uploads'
    end
  end

end