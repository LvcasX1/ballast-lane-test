class AddBorrowingsCountToBooks < ActiveRecord::Migration[8.0]
  def up
    add_column :books, :borrowings_count, :integer, default: 0, null: false

    # Backfill counts for existing data
    say_with_time "Backfilling books.borrowings_count" do
      Book.reset_column_information
      Book.find_each do |book|
        Book.reset_counters(book.id, :borrowings)
      end
    end
  end

  def down
    remove_column :books, :borrowings_count
  end
end
