
# poll every 2 sec
Delayed::Worker.sleep_delay = 2
# separate log file for delayed_job
#Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))

# suppress ActiveRecord logging from delayed_job otherwise we see
# output from tons of queries on the jobs table
#
# adapted from https://github.com/collectiveidea/delayed_job/issues/477
module Delayed
  module Backend
    module ActiveRecord
      class Job
        class << self
          alias_method :reserve_original, :reserve
          def reserve(worker, max_run_time = Worker.max_run_time)
            previous_level = ::ActiveRecord::Base.logger.level
            ::ActiveRecord::Base.logger.level = Logger::WARN if previous_level < Logger::WARN
            value = reserve_original(worker, max_run_time)
            ::ActiveRecord::Base.logger.level = previous_level
            value
          end
        end
      end
    end
  end
end
