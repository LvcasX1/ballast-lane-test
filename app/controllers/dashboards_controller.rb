class DashboardsController < ApplicationController
  # Librarian dashboard
  def librarian
    unless current_user&.librarian?
      return render json: { error: "Access denied." }, status: :forbidden
    end

    total_books = Book.count
    total_borrowed_books = Borrowing.active.count
    books_due_today = Borrowing.due_today.count

    overdue_by_member = Borrowing.overdue
      .includes(:user, :book)
      .group_by(&:user)
      .transform_values { |borrows| borrows.map { |b| { borrowing_id: b.id, book_id: b.book_id, title: b.book.title, due_date: b.due_date } } }

    render json: {
      total_books: total_books,
      total_borrowed_books: total_borrowed_books,
      books_due_today: books_due_today,
      overdue_members: overdue_by_member.map { |user, borrows| { member: { id: user.id, name: user.name, email: user.email_address }, overdue: borrows } }
    }
  end

  # Member dashboard
  def member
    unless current_user&.member?
      return render json: { error: "Access denied." }, status: :forbidden
    end

    my_borrowings = current_user.borrowings.includes(:book)

    active = my_borrowings.active.map { |b| serialize_borrowing(b) }
    overdue = my_borrowings.overdue.map { |b| serialize_borrowing(b) }

    render json: {
      active: active,
      overdue: overdue
    }
  end

  private

  def serialize_borrowing(b)
    {
      id: b.id,
      book: {
        id: b.book_id,
        title: b.book.title,
        author: b.book.author
      },
      borrowed_at: b.borrowed_at,
      due_date: b.due_date,
      returned_at: b.returned_at
    }
  end
end
