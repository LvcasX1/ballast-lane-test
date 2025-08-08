require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @book = books(:book_1)
    @librarian = users(:librarian_one)
  end

  test "should get index (auth required)" do
    get books_url, headers: auth_headers_for(@librarian), as: :json
    assert_response :success
  end

  test "should create book (librarian)" do
    assert_difference("Book.count") do
      post books_url, params: { book: { author: "Author", genre: "Genre", isbn: "isbn-#{SecureRandom.hex(3)}", title: "New Book", total_copies: 3 } }, headers: auth_headers_for(@librarian), as: :json
    end

    assert_response :created
  end

  test "should show book (auth required)" do
    get book_url(@book), headers: auth_headers_for(@librarian), as: :json
    assert_response :success
  end

  test "should update book (librarian)" do
    patch book_url(@book), params: { book: { title: "Updated Title" } }, headers: auth_headers_for(@librarian), as: :json
    assert_response :success
    assert_equal "Updated Title", @book.reload.title
  end

  test "should destroy book (librarian)" do
    # Create a fresh book not referenced by borrowings
    post books_url, params: { book: { author: "Temp", genre: "Temp", isbn: "isbn-#{SecureRandom.hex(3)}", title: "Temp Book", total_copies: 1 } }, headers: auth_headers_for(@librarian), as: :json
    assert_response :created
    new_book_id = JSON.parse(response.body)["id"]

    assert_difference("Book.count", -1) do
      delete book_url(new_book_id), headers: auth_headers_for(@librarian), as: :json
    end

    assert_response :no_content
  end
end
