require 'rails_helper'

RSpec.describe 'Borrowings', type: :request do
  fixtures :users, :books

  let(:member) { users(:member_one) }
  let(:librarian) { users(:librarian_one) }
  let(:book) { books(:book_1) }

  it 'member can borrow available book' do
    expect {
      post '/borrowings', params: { book_id: book.id }, headers: auth_headers_for(member)
    }.to change(Borrowing, :count).by(1)
    expect(response).to have_http_status(:created)
    body = JSON.parse(response.body)
    expect(body['due_date']).to be_present
  end

  it 'cannot borrow if no copies' do
    book.update!(total_copies: 0)
    expect {
      post '/borrowings', params: { book_id: book.id }, headers: auth_headers_for(member)
    }.not_to change(Borrowing, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it 'member cannot borrow same book twice' do
    Borrowing.create!(user: member, book: book, borrowed_at: Time.current, due_date: 2.weeks.from_now)
    expect {
      post '/borrowings', params: { book_id: book.id }, headers: auth_headers_for(member)
    }.not_to change(Borrowing, :count)
    expect(response).to have_http_status(:unprocessable_content)
  end

  it 'only librarian can return' do
    borrowing = Borrowing.create!(user: member, book: book, borrowed_at: Time.current, due_date: 2.weeks.from_now)

    post "/borrowings/#{borrowing.id}/return", headers: auth_headers_for(member)
    expect(response).to have_http_status(:forbidden)

    post "/borrowings/#{borrowing.id}/return", headers: auth_headers_for(librarian)
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body['returned_at']).to be_present
  end
end
