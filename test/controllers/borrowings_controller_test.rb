require "test_helper"

class BorrowingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member_one)
    @librarian = users(:librarian_one)
    @book = books(:book_1)
  end

  test "member can borrow available book" do
    assert_difference("Borrowing.count", 1) do
      post borrowings_url, params: { book_id: @book.id }, headers: auth_headers_for(@member), as: :json
    end
    assert_response :created
    body = JSON.parse(response.body)
    assert body["due_date"].present?
  end

  test "cannot borrow if no copies" do
    @book.update!(total_copies: 0)
    assert_no_difference("Borrowing.count") do
      post borrowings_url, params: { book_id: @book.id }, headers: auth_headers_for(@member), as: :json
    end
    assert_response :unprocessable_entity
  end

  test "member cannot borrow same book twice" do
    Borrowing.create!(user: @member, book: @book, borrowed_at: Time.current, due_date: 2.weeks.from_now)
    assert_no_difference("Borrowing.count") do
      post borrowings_url, params: { book_id: @book.id }, headers: auth_headers_for(@member), as: :json
    end
    assert_response :unprocessable_entity
  end

  test "only librarian can return" do
    borrowing = Borrowing.create!(user: @member, book: @book, borrowed_at: Time.current, due_date: 2.weeks.from_now)

    post return_borrowing_url(borrowing), headers: auth_headers_for(@member), as: :json
    assert_response :forbidden

    post return_borrowing_url(borrowing), headers: auth_headers_for(@librarian), as: :json
    assert_response :ok
    body = JSON.parse(response.body)
    assert body["returned_at"].present?
  end
end
