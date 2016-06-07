class Download < ActiveRecord::Base
  belongs_to :user

  after_create { |download| download.delay(run_at: 1.days.from_now).destroy }

  def to_s
    filename
  end

  def destroy
    path = "downloads/" + id.to_s + "_" + user.username + "_" + filename
    File.delete(path) if File.exist?(path)
    super
  end

end