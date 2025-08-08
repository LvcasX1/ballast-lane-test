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
end
