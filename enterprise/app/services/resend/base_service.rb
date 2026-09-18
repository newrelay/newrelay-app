class Resend::BaseService
  BASE_URI = 'https://api.resend.com'.freeze
  private_constant :BASE_URI

  private

  def headers
    {
      'Authorization' => "Bearer #{api_key}",
      'Content-Type' => 'application/json'
    }
  end

  def api_key
    @api_key ||= GlobalConfigService.load('RESEND_API_KEY', nil)
  end

  def request(method, path, body: nil)
    options = { headers: headers }
    options[:body] = body.to_json if body
    HTTParty.send(method, "#{BASE_URI}#{path}", options)
  end

  def error_messages(response)
    parsed = response.parsed_response
    return ['Resend request failed'] unless parsed.is_a?(Hash)

    Array(parsed['message'].presence || parsed['errors'].presence || ['Resend request failed'])
  end
end
