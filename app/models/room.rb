class Room < ApplicationRecord
  has_many :reservations

  validates_presence_of :code, :capacity
  validates_uniqueness_of :code
  validates_numericality_of :capacity, greater_than: 0, less_than_or_equal_to: 10

  scope :minimum_capacity_of, ->(guests) {
    where('capacity >= ?', guests)
  }

  scope :unavailable_for_period, ->(query_start_date, query_end_date) {
    joins(:reservations).where('start_date <=? AND end_date >= ?', query_end_date, query_start_date).uniq
  }
end
