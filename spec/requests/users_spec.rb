require 'rails_helper'

RSpec.describe 'Users', type: :request do
  fixtures :users

  let(:librarian) { users(:librarian_one) }
  let(:member) { users(:member_one) }

  it 'indexes users (auth required)' do
    get '/users', headers: auth_headers_for(librarian)
    expect(response).to have_http_status(:ok)
  end

  it 'signs up via /sign-up' do
    email = "user_#{SecureRandom.hex(4)}@example.com"
    expect {
      post '/sign-up', params: { user: { name: 'New User', email_address: email, password: 'password', password_confirmation: 'password' } }
    }.to change(User, :count).by(1)
    expect(response).to have_http_status(:created)
    body = JSON.parse(response.body)
    expect(body['auth_token']).to be_present
    expect(body.dig('user', 'name')).to eq('New User')
    expect(body.dig('user', 'email_address')).to eq(email)
  end

  it 'shows a user' do
    get "/users/#{member.id}", headers: auth_headers_for(librarian)
    expect(response).to have_http_status(:ok)
  end

  it 'updates a user' do
    patch "/users/#{member.id}", params: { user: { name: 'Updated Name' } }, headers: auth_headers_for(librarian)
    expect(response).to have_http_status(:ok)
    expect(member.reload.name).to eq('Updated Name')
  end

  it 'destroys a user without FK issues' do
    fresh = User.create!(name: 'Temp', email_address: "temp_#{SecureRandom.hex(4)}@example.com", password: 'password', password_confirmation: 'password')
    expect {
      delete "/users/#{fresh.id}", headers: auth_headers_for(librarian)
    }.to change(User, :count).by(-1)
    expect(response).to have_http_status(:no_content)
  end
end
