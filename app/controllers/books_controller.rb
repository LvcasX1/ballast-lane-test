class BooksController < ApplicationController
  before_action :set_book, only: %i[ show update destroy ]
  before_action :require_librarian, except: [ :index ]

  # GET /books
  def index
    @books = Book.search(filters)

    render json: @books.as_json(methods: :borrowings_count)
  end

  # GET /books/1
  def show
    render json: @book.as_json(methods: :borrowings_count)
  end

  # POST /books
  def create
    @book = Book.new(book_params)

    if @book.save
      render json: @book, status: :created, location: @book
    else
      render json: @book.errors, status: :unprocessable_content
    end
  end

  # PATCH/PUT /books/1
  def update
    if @book.update(book_params)
      render json: @book
    else
      render json: @book.errors, status: :unprocessable_content
    end
  end

  # DELETE /books/1
  def destroy
    @book.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_book
      @book = Book.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def book_params
      params.expect(book: [ :title, :author, :genre, :isbn, :total_copies ])
    end

    def require_librarian
      unless current_user&.librarian?
        render json: { error: "Access denied." }, status: :forbidden
      end
    end
end
