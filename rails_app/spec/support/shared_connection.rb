module SharedConnection
  mattr_accessor :connection
end

module SharedConnectionPatch
  def connection
    SharedConnection.connection || super
  end
end

# Feature specs run the Rack app in a separate thread. Reusing the same
# connection lets browser-driven requests participate in the example
# transaction instead of forcing per-example truncation.
ActiveRecord::Base.singleton_class.prepend(SharedConnectionPatch)

