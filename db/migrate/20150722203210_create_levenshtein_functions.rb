
require 'sdbmss/mysql'

class CreateLevenshteinFunctions < ActiveRecord::Migration
  def change
    SDBMSS::Mysql.create_functions
  end
end
