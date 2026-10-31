# frozen_string_literal: true

module McpOnRuby
  # Turns the controller's Rack response into an MCP tool result an agent can act on.
  module Result
    JSON_TYPE = %r{\Aapplication/(?:[\w.+-]+\+)?json\b}i
    HTML_TYPE = %r{\Atext/html\b}i

    # Sign-in pages apps redirect unauthenticated requests to: Rails 8 authentication (/session/new),
    # Devise (/users/sign_in), and common /login and /signin routes.
    SIGN_IN_PATH = %r{/(?:session/new|sign_?in|log_?in)/?\z}i

    module_function

    def from_rack(status, headers, body)
      text = read(body)
      content_type = header(headers, "content-type").to_s
      json = parse_json(text) if content_type.match?(JSON_TYPE)

      case status
      when 200..299 then success(status, text, json, content_type)
      when 300..399 then redirect(status, header(headers, "location"))
      when 400..499 then client_error(status, text, json)
      else error(status, "Internal server error (#{status})")
      end
    end

    def internal_error
      error(500, "Internal server error (500)")
    end

    def success(status, text, json, content_type)
      return text_response("Success (#{status}), no content") if text.empty?
      return MCP::Tool::Response.new([text_block(text)], structured_content: json) unless json.nil?
      if content_type.match?(HTML_TYPE)
        return error(status, "The action responded with HTML; render JSON for MCP tools")
      end

      text_response(text)
    end

    def redirect(status, location)
      if location && URI(location).path.to_s.match?(SIGN_IN_PATH)
        error(status, "Not authenticated: the app redirected to its sign-in page (#{location})")
      else
        error(status, "Redirected to #{location || "another page"}; redirects are not followed")
      end
    rescue URI::InvalidURIError
      error(status, "Redirected to #{location}; redirects are not followed")
    end

    def client_error(status, text, json)
      message = {
        401 => "Not authenticated (401)",
        403 => "Not permitted (403)",
        404 => "Not found (404)",
        422 => "Unprocessable (422)"
      }.fetch(status) { "Request failed (#{status})" }

      detail = json.nil? ? nil : text
      error(status, [message, detail].compact.join(": "), json)
    end

    def error(status, message, body = nil)
      structured = { "status" => status }
      structured["body"] = body unless body.nil?
      MCP::Tool::Response.new([text_block(message)], structured_content: structured, error: true)
    end

    def text_response(text)
      MCP::Tool::Response.new([text_block(text)])
    end

    def text_block(text)
      { type: "text", text: }
    end

    def read(body)
      text = +""
      body.each { |chunk| text << chunk.to_s }
      text
    ensure
      body.close if body.respond_to?(:close)
    end

    def header(headers, name)
      headers[name] || headers.find { |key, _| key.to_s.casecmp?(name) }&.last
    end

    def parse_json(text)
      JSON.parse(text) unless text.empty?
    rescue JSON::ParserError
      nil
    end
  end
end
