class Page < ActiveRecord::Base
  validates :name, uniqueness: true, presence: true
  validates :filename, uniqueness: true, presence: true

  def ext
    filename.split('.').last
  end

  def location
    if ext == "pdf"
      'static/docs'
    elsif category == 'tooltip'
      'static/tooltips'
    else
      'static/uploads'
    end
  end

  def to_s
    name
  end

  def path
    if ext == "pdf"
      "/#{location}/#{URI.encode filename}"
    else
      Rails.root.join('public', "#{location}", filename)
    end
  end

end