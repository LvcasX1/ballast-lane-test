require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  fixtures :users

  let(:user) { users(:librarian_one) }

  it 'logs in with valid credentials and returns an auth token' do
    post '/session', params: { email_address: user.email_address, password: 'password' }
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body['auth_token']).to be_present
    expect(body.dig('user', 'email_address')).to eq(user.email_address)
  end

  it 'rejects invalid credentials' do
    post '/session', params: { email_address: user.email_address, password: 'wrong-password' }
    expect(response).to have_http_status(:unauthorized)
  end

  it 'logs out and invalidates the auth token' do
    # Login first to get a token
    post '/session', params: { email_address: user.email_address, password: 'password' }
    token = JSON.parse(response.body)['auth_token']
    expect(token).to be_present

    # Logout
    delete '/session', headers: { 'Authorization' => "Bearer #{token}" }
    expect(response).to have_http_status(:ok)
    expect(user.reload.auth_token).to be_nil
  end
end
