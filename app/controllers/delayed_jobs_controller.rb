# what is this used for?
require 'yaml'

class DelayedJobsController < ApplicationController

  before_action :authenticate_user!, only: [:index]

  def index
    @jobs = Delayed::Job.all.order("locked_at desc", "run_at desc")
  end

end
