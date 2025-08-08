require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @librarian = users(:librarian_one)
    @member = users(:member_one)
    @book = books(:book_1)
  end

  test "librarian dashboard returns counts and overdue members" do
    # Seed one active borrowing and one overdue
    Borrowing.create!(user: @member, book: @book, borrowed_at: 3.weeks.ago, due_date: 2.weeks.ago)

    get "/dashboard/librarian", headers: auth_headers_for(@librarian), as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert body["total_books"].is_a?(Integer)
    assert body["total_borrowed_books"].is_a?(Integer)
    assert body["books_due_today"].is_a?(Integer)
    assert body["overdue_members"].is_a?(Array)
  end

  test "member dashboard returns active and overdue lists" do
    # One active and one overdue for member
    Borrowing.create!(user: @member, book: @book, borrowed_at: 1.day.ago, due_date: 1.day.from_now)
    Borrowing.create!(user: @member, book: books(:book_2), borrowed_at: 3.weeks.ago, due_date: 2.weeks.ago)

    get "/dashboard/member", headers: auth_headers_for(@member), as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert body["active"].is_a?(Array)
    assert body["overdue"].is_a?(Array)
  end

  test "member dashboard forbidden for librarian" do
    get "/dashboard/member", headers: auth_headers_for(@librarian), as: :json
    assert_response :forbidden
  end

  test "librarian dashboard forbidden for member" do
    get "/dashboard/librarian", headers: auth_headers_for(@member), as: :json
    assert_response :forbidden
  end
end
