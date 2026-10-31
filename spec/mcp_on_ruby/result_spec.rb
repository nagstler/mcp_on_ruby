# frozen_string_literal: true

RSpec.describe McpOnRuby::Result do
  def result(status, body, headers = { "content-type" => "application/json" })
    described_class.from_rack(status, headers, [body])
  end

  it "parses JSON media types with suffixes" do
    response = result(200, '{"data":[]}', { "Content-Type" => "application/vnd.api+json; charset=utf-8" })

    expect(response.structured_content).to eq("data" => [])
  end

  it "treats malformed JSON as text" do
    response = result(200, "{oops")

    expect(response.structured_content).to be_nil
    expect(response.content).to eq([{ type: "text", text: "{oops" }])
  end

  it "keeps JSON scalars as structured content" do
    expect(result(200, "42").structured_content).to eq(42)
  end

  it "describes other client errors with their status" do
    response = result(409, '{"error":"conflict"}')

    expect(response.content.first[:text]).to eq('Request failed (409): {"error":"conflict"}')
    expect(response.structured_content).to eq("status" => 409, "body" => { "error" => "conflict" })
  end

  it "omits non-JSON client error bodies" do
    response = result(400, "<h1>Bad</h1>", { "content-type" => "text/html" })

    expect(response.content.first[:text]).to eq("Request failed (400)")
    expect(response.structured_content).to eq("status" => 400)
  end

  it "never exposes server error bodies" do
    response = result(503, '{"secret":"stacktrace"}')

    expect(response.content.first[:text]).to eq("Internal server error (503)")
    expect(response.structured_content).to eq("status" => 503)
  end

  it "reports redirects to a sign-in page as unauthenticated" do
    %w[https://app.test/session/new https://app.test/users/sign_in /login http://app.test/signin/].each do |location|
      response = described_class.from_rack(302, { "location" => location }, [""])

      expect(response.content.first[:text])
        .to eq("Not authenticated: the app redirected to its sign-in page (#{location})")
    end
  end

  it "keeps other redirects as redirects" do
    %w[https://app.test/orders/5 https://app.test/sessions_report /blog/how-to-login-faster].each do |location|
      response = described_class.from_rack(303, { "location" => location }, [""])

      expect(response.content.first[:text]).to eq("Redirected to #{location}; redirects are not followed")
    end
  end

  it "tolerates unparseable Location headers" do
    response = described_class.from_rack(302, { "location" => "http://bad host/" }, [""])

    expect(response.content.first[:text]).to eq("Redirected to http://bad host/; redirects are not followed")
  end

  it "describes redirects without a Location header" do
    response = described_class.from_rack(302, {}, [""])

    expect(response.content.first[:text]).to eq("Redirected to another page; redirects are not followed")
  end

  it "closes the body" do
    closed = false
    body = Rack::BodyProxy.new(["{}"]) { closed = true }

    described_class.from_rack(200, { "content-type" => "application/json" }, body)

    expect(closed).to be(true)
  end
end
