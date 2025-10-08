# Precompile assets before running tests to avoid timeouts.
# Do not precompile if webpack-dev-server is running (NOTE: MUST be launched with RAILS_ENV=test)
RSpec.configure do |config|
  config.before(:suite) do
    examples = RSpec.world.filtered_examples.values.flatten
    has_no_feature_tests = examples.none? { |example| example.metadata[:type] == :feature }

    if has_no_feature_tests
      $stdout.puts "\n🚀️️  No feature test selected. Skip assets compilation.\n"
      next
    end

    $stdout.puts "\n🐢  Precompiling assets.\n"

    start = Time.current
    begin
      require 'rake'
      Rails.application.load_tasks
      Rake::Task['assets:precompile'].invoke
    ensure
      $stdout.puts "Finished in #{(Time.current - start).round(2)} seconds"
    end
  end
end
