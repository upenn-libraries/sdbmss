# request_store's railtie calls insert_after on the middleware stack, which
# raises FrozenError when the middleware stack array is already frozen.
# This happens in Rails 5.2 test environment. Guard against it.
if defined?(ActionDispatch::MiddlewareStack)
  module MiddlewareStackFrozenGuard
    def insert(index, *args)
      super
    rescue FrozenError
      self
    end

    def insert_after(index, *args)
      super
    rescue FrozenError
      self
    end
  end

  ActionDispatch::MiddlewareStack.prepend(MiddlewareStackFrozenGuard)
end
