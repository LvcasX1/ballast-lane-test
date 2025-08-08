class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ create ]

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      user.regenerate_auth_token!
      render json: {
        auth_token: user.auth_token,
        user: {
          id: user.id,
          name: user.name,
          email_address: user.email_address,
          role: user.role
        }
      }, status: :ok
    else
      render json: { error: "Invalid credentials" }, status: :unauthorized
    end
  end

  def destroy
    if current_user
      current_user.update!(auth_token: nil)
      render json: { message: "Logged out successfully" }, status: :ok
    else
      render json: { error: "Not authenticated" }, status: :unauthorized
    end
  end
end
