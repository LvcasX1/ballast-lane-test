module AuthHelpers
  def auth_headers_for(user)
    user.regenerate_auth_token!
    { "Authorization" => "Bearer #{user.auth_token}" }
  end
end
