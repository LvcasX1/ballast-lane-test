ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

# Common helpers for integration tests
class ActionDispatch::IntegrationTest
  # Generate Authorization header for a given user
  def auth_headers_for(user)
    user.regenerate_auth_token!
    { "Authorization" => "Bearer #{user.auth_token}" }
  end
end
