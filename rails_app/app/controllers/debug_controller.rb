
class DebugController < ApplicationController

  # for testing whether exception_notification gem works
  def raise_error
    raise "This is an error!"
  end

end
