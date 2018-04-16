module TellBunny

  require 'bunny'

  extend ActiveSupport::Concern

  included do
    after_save do |model|
      connection = Bunny.new
      connection.start

      ch = connection.create_channel

      q = ch.queue("test")

      q.publish("#{model.to_rdf}")

      # close the connection
      connection.stop
    end
  end

  def to_rdf
    %Q(
      sdbm:names/#{id} sdbm:names_id #{id}
      sdbm:names/#{id} sdbm:names_name #{name}
      sdbm:names/#{id} sdbm:names_viaf_id #{viaf_id}
      sdbm:names/#{id} sdbm:names_other_info #{other_info}
      sdbm:names/#{id} sdbm:names_subtype #{subtype}
    )
  end
end