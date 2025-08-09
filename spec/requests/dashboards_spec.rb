require 'rails_helper'

RSpec.describe 'Dashboards', type: :request do
  fixtures :users, :books

  let(:librarian) { users(:librarian_one) }
  let(:member) { users(:member_one) }
  let(:book) { books(:book_1) }

  it 'librarian dashboard returns counts and overdue members' do
    Borrowing.create!(user: member, book: book, borrowed_at: 3.weeks.ago, due_date: 2.weeks.ago)

    get '/dashboards/librarian', headers: auth_headers_for(librarian)
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body['total_books']).to be_a(Integer)
    expect(body['total_borrowed_books']).to be_a(Integer)
    expect(body['books_due_today']).to be_a(Integer)
    expect(body['overdue_members']).to be_an(Array)
    if body['overdue_members'].any?
      first_member = body['overdue_members'].first
      expect(first_member['overdue'].first).to include('borrowing_id')
    end
  end

  it 'member dashboard returns active and overdue lists' do
    Borrowing.create!(user: member, book: book, borrowed_at: 1.day.ago, due_date: 1.day.from_now)
    Borrowing.create!(user: member, book: books(:book_2), borrowed_at: 3.weeks.ago, due_date: 2.weeks.ago)

    get '/dashboards/member', headers: auth_headers_for(member)
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body['active']).to be_an(Array)
    expect(body['overdue']).to be_an(Array)
  end

  it 'member dashboard forbidden for librarian' do
    get '/dashboards/member', headers: auth_headers_for(librarian)
    expect(response).to have_http_status(:forbidden)
  end

  it 'librarian dashboard forbidden for member' do
    get '/dashboards/librarian', headers: auth_headers_for(member)
    expect(response).to have_http_status(:forbidden)
  end
end
