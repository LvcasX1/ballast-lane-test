class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :borrowings

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  enum(:role, { member: 0, librarian: 1 })

  before_create :generate_auth_token

  def regenerate_auth_token!
    generate_auth_token
    save!
  end

  private

  def generate_auth_token
    loop do
      self.auth_token = SecureRandom.urlsafe_base64(32)
      break unless User.exists?(auth_token: auth_token)
    end
  end
end
