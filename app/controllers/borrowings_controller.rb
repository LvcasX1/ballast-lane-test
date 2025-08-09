class BorrowingsController < ApplicationController
  before_action :set_book, only: [ :create ]
  before_action :set_borrowing, only: [ :show, :update, :destroy, :return_book ]

  # GET /borrowings
  def index
    scope = current_user.librarian? ? Borrowing.all : current_user.borrowings
    render json: scope.order(created_at: :desc).map { |b| borrowing_response(b) }
  end

  # POST /borrowings
  # Body: { book_id: 123 }
  def create
    unless current_user.member?
      return render json: { error: "Only members can borrow books" }, status: :forbidden
    end

    borrowing = Borrowing.new(user: current_user, book: @book)

    if borrowing.save
      render json: borrowing_response(borrowing), status: :created
    else
      render json: { errors: borrowing.errors.full_messages }, status: :unprocessable_content
    end
  end

  # GET /borrowings/:id
  def show
    unless current_user.librarian? || @borrowing.user_id == current_user.id
      return render json: { error: "Access denied" }, status: :forbidden
    end

    render json: borrowing_response(@borrowing)
  end

  # PATCH/PUT /borrowings/:id
  def update
    unless current_user.librarian?
      return render json: { error: "Only librarians can update borrowings" }, status: :forbidden
    end

    if @borrowing.update(borrowing_params)
      render json: borrowing_response(@borrowing), status: :ok
    else
      render json: { errors: @borrowing.errors.full_messages }, status: :unprocessable_content
    end
  end

  # DELETE /borrowings/:id
  def destroy
    unless current_user.librarian?
      return render json: { error: "Only librarians can delete borrowings" }, status: :forbidden
    end

    @borrowing.destroy!
    head :no_content
  end

  # POST /borrowings/:id/return
  def return_book
    unless current_user.librarian?
      return render json: { error: "Only librarians can mark returns" }, status: :forbidden
    end

    if @borrowing.returned_at.present?
      return render json: { message: "Already returned" }, status: :ok
    end

    @borrowing.return!
    render json: borrowing_response(@borrowing), status: :ok
  end

  private

  def set_book
    @book = Book.find_by(id: params[:book_id])
    render json: { error: "Book not found" }, status: :not_found unless @book
  end

  def set_borrowing
    @borrowing = Borrowing.find(params[:id])
  end

  def borrowing_params
    params.expect(borrowing: [ :due_date ])
  end

  def borrowing_response(b)
    {
      id: b.id,
      user_id: b.user_id,
      book_id: b.book_id,
      borrowed_at: b.borrowed_at,
      due_date: b.due_date,
      returned_at: b.returned_at
    }
  end
end
