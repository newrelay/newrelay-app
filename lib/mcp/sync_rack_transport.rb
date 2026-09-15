# Loaded via `require` in config/initializers/fast_mcp.rb, not Zeitwerk, so the
# implicit `Mcp` namespace module doesn't exist yet -- compact `class Mcp::X` would raise.
# rubocop:disable Style/ClassAndModuleChildren
module Mcp
  class SyncRackTransport < FastMcp::Transports::RackTransport
    def send_message(message)
      Thread.current[:mcp_sync_response] = message
      # No SSE clients can ever be registered (see handle_sse_request below),
      # so there is nothing to broadcast to -- this transport is synchronous-only.
    end

    private

    def handle_sse_request(_request, _env)
      endpoint_not_found_response
    end

    def process_json_request_with_server(request, server)
      Thread.current[:mcp_sync_response] = nil
      status, headers, _original_body = super
      captured = Thread.current[:mcp_sync_response]
      Thread.current[:mcp_sync_response] = nil
      body = captured.nil? ? '{}' : JSON.generate(captured)
      [status, headers, [body]]
    end
  end
end
# rubocop:enable Style/ClassAndModuleChildren
