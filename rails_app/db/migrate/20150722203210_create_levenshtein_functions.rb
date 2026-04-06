
require 'sdbmss/mysql'

class CreateLevenshteinFunctions < ActiveRecord::Migration[4.2]
  def change
    SDBMSS::Mysql.create_functions
  end
end
