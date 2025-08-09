class Borrowing < ApplicationRecord
  belongs_to :user
  belongs_to :book, counter_cache: true

  validates :user_id, presence: true
  validates :book_id, presence: true

  validate :book_must_have_available_copies, on: :create
  validate :user_cannot_borrow_same_book_twice, on: :create

  before_create :set_borrowed_and_due_dates

  scope :active, -> { where(returned_at: nil) }
  scope :due_today, -> {
    range = Time.current.beginning_of_day..Time.current.end_of_day
    active.where(due_date: range)
  }
  scope :overdue, -> { active.where("due_date < ?", Time.current) }
  scope :not_overdue, -> { active.where("due_date > ?", Time.current) }

  def return!
    update!(returned_at: Time.current)
  end

  private

  def book_must_have_available_copies
    errors.add(:base, "No available copies for this book") unless book&.available?
  end

  def user_cannot_borrow_same_book_twice
    return unless user && book

    if book.currently_borrowed_by?(user)
      errors.add(:base, "User has already borrowed this book")
    end
  end

  def set_borrowed_and_due_dates
    self.borrowed_at ||= Time.current
    self.due_date ||= 2.weeks.from_now
  end
end
