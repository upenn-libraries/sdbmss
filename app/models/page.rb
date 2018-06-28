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

  def contents
    File.open(Rails.root.join('public', "#{location}", filename), 'r') do |file|
      @filecontents = sanitize(file.read)
    end
    @filecontents
  end

  def sanitize(original)
    ActionController::Base.helpers.sanitize original, tags: %w(figcaption figure img p pre table td tr th tbody li ul ol span div code b i br strong em a legend h1 h2 h3 h4 h5), attributes: %w(src href class style target)
  end

end