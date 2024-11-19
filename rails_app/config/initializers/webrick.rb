
# monkey-patch webrick so it doesn't raise
# WEBrick::HTTPStatus::RequestURITooLarge exceptions on GET requests
# with very long URIs, which can happen on some ajax requests we do.

if defined?(WEBrick::HTTPRequest)
  WEBrick::HTTPRequest.const_set("MAX_URI_LENGTH", 10240)
end
