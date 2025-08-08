class Book < ApplicationRecord
  has_many :borrowings

  scope :search_by_title, ->(title) { where("title ILIKE ?", "%#{title}%") if title.present? }
  scope :search_by_author, ->(author) { where("author ILIKE ?", "%#{author}%") if author.present? }
  scope :search_by_genre, ->(genre) { where("genre ILIKE ?", "%#{genre}%") if genre.present? }
  scope :search_by_isbn, ->(isbn) { where("isbn ILIKE ?", "%#{isbn}%") if isbn.present? }

  def self.search(params)
    books = all
    books = books.search_by_title(params[:title])
    books = books.search_by_author(params[:author])
    books = books.search_by_genre(params[:genre])
    books = books.search_by_isbn(params[:isbn])
    books
  end

  def active_borrowings_count
    borrowings.where(returned_at: nil).count
  end

  def available_copies
    return 0 if total_copies.nil?
    [ total_copies - active_borrowings_count, 0 ].max
  end

  def available?
    available_copies > 0
  end

  def currently_borrowed_by?(user)
    borrowings.exists?(user_id: user.id, returned_at: nil)
  end
end
