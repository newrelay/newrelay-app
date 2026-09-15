module McpHelpers
  def mcp_call(tool_name, arguments: {}, token: nil, id: 1)
    headers = { 'CONTENT_TYPE' => 'application/json' }
    headers['Authorization'] = "Bearer #{token}" if token

    post '/mcp/messages',
         params: {
           jsonrpc: '2.0',
           method: 'tools/call',
           params: { name: tool_name, arguments: arguments },
           id: id
         }.to_json,
         headers: headers
  end

  def mcp_result
    JSON.parse(response.body)['result']
  end

  def mcp_error
    JSON.parse(response.body)['error']
  end

  def mcp_content_json
    JSON.parse(mcp_result['content'].first['text'])
  end
end

RSpec.configure do |config|
  config.include McpHelpers, type: :request
end
