# This is a library that creates "reference data", containing entries
# from actual catalogs. See the /reference_data directory in the
# project root for digital copies of the original sources.
#
# The purpose of this is to verify we can properly store all types of
# entries, and to keep a normative record of the fields where various
# bits of data should live, since this is not always obvious or easy
# to remember for the many types of sources and entries.
#
# Think of this as an "integration test" of all our models as a
# organic whole.
#
# This gets used by the test suite, and also in development to
# re-create data in case we want to examine something.

module SDBMSS
end

require_relative "reference_data/ref_data_base"
require_relative "reference_data/archive_builders"
require_relative "reference_data/catalog_builders"
require_relative "reference_data/source_builders"

module SDBMSS::ReferenceData
  class << self
    def create_all
      DericciArchive.new
      JonathanHill.new
      PennCatalog.new
      Pirages.new
      DeRicci.new
      Ader.new
      Email.new
      PersonalObservation.new
      EBay.new
      VanDeWiele.new
      Duke.new
      Steinhauser.new
      Manuscripts.new
    end
  end
end
