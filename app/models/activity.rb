class Activity < ApplicationRecord
  belongs_to :trip
  enum category: {
    eat: 0,
    do: 1,
    explore: 2
  }

  enum status: {
    pending: 0,
    favourite: 1,
    added: 2
  }

  scope :pending_eat, -> { where(category: :eat, status: :pending) }
  scope :pending_do, -> { where(category: :do, status: :pending) }
  scope :pending_explore, -> { where(category: :explore, status: :pending) }
  scope :selected, -> { where(status: %i[added favourite]) }
end
