
module SDBMSS

  module IDS

    class << self

      # returns a public string identifier for a given model (as
      # either a class or string) and integer id. This exists so that
      # we can construct identifiers without actually having a model
      # object instance.
      def get_public_id_for_model(model, id)
        public_id = nil
        model_str = model
        if model.class == Class
          model_str = model.to_s
        end
        case model_str
        when "Entry"
          public_id = "SDBM_#{id}"
        when "Manuscript"
          public_id = "SDBM_MS_#{id}"
        when "Name"
          public_id = "SDBM_NAME_#{id}"
        when "Source"
          public_id = "SDBM_SOURCE_#{id}"
        when "Place"
          public_id = "SDBM_PLACE_#{id}"
        when "Language"
          public_id = "SDBM_LNG_#{id}"
        when "Comment"
          public_id = "SDBM_COMMENT_#{id}"
        end
        public_id
      end

    end

  end

end
