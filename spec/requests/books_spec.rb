require 'rails_helper'

RSpec.describe 'Books', type: :request do
  fixtures :users, :books

  let(:librarian) { users(:librarian_one) }
  let(:book) { books(:book_1) }

  it 'lists books (auth required)' do
    get '/books', headers: auth_headers_for(librarian)
    expect(response).to have_http_status(:ok)
  end

  it 'creates a book (librarian)' do
    expect {
      post '/books', params: { book: { author: 'Author', genre: 'Genre', isbn: "isbn-#{SecureRandom.hex(3)}", title: 'New Book', total_copies: 3 } }, headers: auth_headers_for(librarian)
    }.to change(Book, :count).by(1)
    expect(response).to have_http_status(:created)
  end

  it 'shows a book (auth required)' do
    get "/books/#{book.id}", headers: auth_headers_for(librarian)
    expect(response).to have_http_status(:ok)
  end

  it 'updates a book (librarian)' do
    patch "/books/#{book.id}", params: { book: { title: 'Updated Title' } }, headers: auth_headers_for(librarian)
    expect(response).to have_http_status(:ok)
    expect(book.reload.title).to eq('Updated Title')
  end

  it 'destroys a book (librarian)' do
    # Create a fresh, unreferenced book
    post '/books', params: { book: { author: 'Temp', genre: 'Temp', isbn: "isbn-#{SecureRandom.hex(3)}", title: 'Temp Book', total_copies: 1 } }, headers: auth_headers_for(librarian)
    expect(response).to have_http_status(:created)
    new_book_id = JSON.parse(response.body)['id']

    expect {
      delete "/books/#{new_book_id}", headers: auth_headers_for(librarian)
    }.to change(Book, :count).by(-1)
    expect(response).to have_http_status(:no_content)
  end
end
