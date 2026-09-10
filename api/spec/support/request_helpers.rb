# frozen_string_literal: true

module RequestHelpers
  def json = JSON.parse(response.body)

  def headers_for(community, extra = {})
    { "X-Community-Slug" => community.slug,
      "Origin" => "http://www.example.com",
      "CONTENT_TYPE" => "application/json" }.merge(extra)
  end

  # Signs in through the real endpoint rather than stubbing, so the cookie, the Origin
  # check and the session lookup are all exercised by every request spec.
  def sign_in(user, community, password: "correct-horse-battery")
    post "/auth/login",
         params: { email_address: user.email_address, password: password }.to_json,
         headers: headers_for(community)
    expect(response).to have_http_status(:created)
  end
end
