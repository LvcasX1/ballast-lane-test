module TokenAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def authenticated?
    current_user.present?
  end

  def current_user
    @current_user ||= authenticate_with_token
  end

  def authenticate_with_token
    token = extract_token_from_header
    return nil unless token

    User.find_by(auth_token: token)
  end

  def extract_token_from_header
    authorization_header = request.headers["Authorization"]
    return nil unless authorization_header

    # Support "Bearer TOKEN" format
    if authorization_header.start_with?("Bearer ")
      authorization_header.split(" ").last
    else
      authorization_header
    end
  end

  def require_authentication
    unless authenticated?
      render json: { error: "Authentication required" }, status: :unauthorized
    end
  end
end
