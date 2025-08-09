require 'rails_helper'

RSpec.describe 'Borrowings', type: :request do
  fixtures :users, :books

  let(:member) { users(:member_one) }
  let(:member2) { users(:member_two) }
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

  it 'lists borrowings for librarian (all records)' do
    b1 = Borrowing.create!(user: member, book: book, borrowed_at: Time.current, due_date: 2.weeks.from_now)
    b2 = Borrowing.create!(user: member2, book: books(:book_2), borrowed_at: Time.current, due_date: 2.weeks.from_now)

    get '/borrowings', headers: auth_headers_for(librarian)
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body.map { |h| h['id'] }).to include(b1.id, b2.id)
  end

  it 'lists only own borrowings for member' do
    own = Borrowing.create!(user: member, book: book, borrowed_at: Time.current, due_date: 2.weeks.from_now)
    other = Borrowing.create!(user: member2, book: books(:book_2), borrowed_at: Time.current, due_date: 2.weeks.from_now)

    get '/borrowings', headers: auth_headers_for(member)
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    ids = body.map { |h| h['id'] }
    expect(ids).to include(own.id)
    expect(ids).not_to include(other.id)
  end

  it "forbids member viewing someone else's borrowing" do
    other = Borrowing.create!(user: member2, book: books(:book_2), borrowed_at: Time.current, due_date: 2.weeks.from_now)

    get "/borrowings/#{other.id}", headers: auth_headers_for(member)
    expect(response).to have_http_status(:forbidden)
  end

  it 'forbids member updating a borrowing' do
    b = Borrowing.create!(user: member, book: book, borrowed_at: Time.current, due_date: 2.weeks.from_now)

    patch "/borrowings/#{b.id}", params: { borrowing: { due_date: 3.weeks.from_now.iso8601 } }, headers: auth_headers_for(member)
    expect(response).to have_http_status(:forbidden)
  end

  it 'allows librarian to update due_date' do
    b = Borrowing.create!(user: member, book: book, borrowed_at: Time.current, due_date: 2.weeks.from_now)
    new_due = 4.weeks.from_now.change(usec: 0) # normalize for string compare

    patch "/borrowings/#{b.id}", params: { borrowing: { due_date: new_due.iso8601 } }, headers: auth_headers_for(librarian)
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(Time.parse(body['due_date']).to_i).to eq(new_due.to_i)
  end

  it 'allows librarian to destroy a borrowing' do
    b = Borrowing.create!(user: member, book: book, borrowed_at: Time.current, due_date: 2.weeks.from_now)

    expect {
      delete "/borrowings/#{b.id}", headers: auth_headers_for(librarian)
    }.to change(Borrowing, :count).by(-1)
    expect(response).to have_http_status(:no_content)
  end

  it 'forbids member from destroying a borrowing' do
    b = Borrowing.create!(user: member, book: book, borrowed_at: Time.current, due_date: 2.weeks.from_now)

    expect {
      delete "/borrowings/#{b.id}", headers: auth_headers_for(member)
    }.not_to change(Borrowing, :count)
    expect(response).to have_http_status(:forbidden)
  end
end
