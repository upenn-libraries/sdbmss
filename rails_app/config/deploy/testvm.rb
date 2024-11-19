
# for Jeff's testvm environment, used for testing changes before they
# go to staging machine

set :rails_env, 'staging'

set :branch, 'development'

role :app, %w{jeffchiu@testvm}
role :web, %w{jeffchiu@testvm}
