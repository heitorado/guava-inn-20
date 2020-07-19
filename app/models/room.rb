class Room < ApplicationRecord
  has_many :reservations, dependent: :destroy

  validates_presence_of :code, :capacity
  validates_uniqueness_of :code
  validates_length_of :code, maximum: 12
  validates_numericality_of :capacity, greater_than: 0, less_than_or_equal_to: 10
  validates_length_of :notes, maximum: 512

  after_find :calculate_occupancy_rates
  attr_reader :week_occupancy_rate, :month_occupancy_rate

  scope :minimum_capacity_of, ->(guests) {
    where('capacity >= ?', guests)
  }

  scope :unavailable_for_period, ->(query_start_date, query_end_date) {
    joins(:reservations).where('start_date < ? AND end_date > ?', query_end_date, query_start_date).uniq
  }

  def occupancy_rate_for_the_next(n_days)
    return 0 if reservations.blank?

    # Set the observation boundaries for calculating the occupancy rate:
    # Starting tomorrow and to n_days after today
    rate_start_date = Date.tomorrow
    rate_end_date = n_days.days.from_now.to_date

    # Query for existent reservations that overlap with the dates
    current_reservations = reservations.where('start_date <= ? AND end_date > ?', rate_end_date, rate_start_date)
                                       .order(:start_date)

    return 0 if current_reservations.blank?

    occupied_days = current_reservations.map(&:duration).sum

    # See if there is an overlap between the 'edge' reservations and the date range and
    # remove extra days if they overlap with the selected range.
    # Since when we remove the right 'edge' beyond the observation boundary we are cutting half
    # a day from the last boundary day. And since half a day from 0:00 to 12:00 the room is considered
    # available (which it isn't) we need to 'add back' that day (since the room is occupied).
    occupied_days -= [(rate_start_date - current_reservations.first.start_date), 0].max
    occupied_days -= [(current_reservations.last.end_date - rate_end_date) - 1.0, 0].max

    # At last, return the percentual value of occupancy rate (days_occupied/days_observed)
    ((occupied_days / n_days.to_f) * 100).to_i
  end

  private

  def calculate_occupancy_rates
    @week_occupancy_rate = occupancy_rate_for_the_next(7)
    @month_occupancy_rate = occupancy_rate_for_the_next(30)
  end
end
