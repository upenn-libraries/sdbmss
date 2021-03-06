class Download < ActiveRecord::Base
  belongs_to :user

  after_create { |download| download.delay(run_at: 1.days.from_now).destroy }

  def to_s
    filename
  end

  # when the model is deleted, remove the associated file as well
  def destroy
    path = "tmp/" + id.to_s + "_" + user.username + "_" + filename
    File.delete(path) if File.exist?(path)
    super
  end

  def get_path
    id.to_s + "_" + user.to_s + "_" + filename
  end

end