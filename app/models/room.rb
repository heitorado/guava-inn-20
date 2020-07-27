class Room < ApplicationRecord
  has_many :reservations, dependent: :destroy

  validates_presence_of :code, :capacity
  validates_uniqueness_of :code
  validates_length_of :code, maximum: 12
  validates_numericality_of :capacity, greater_than: 0, less_than_or_equal_to: 10
  validates_length_of :notes, maximum: 512

  validate :allowed_to_lower_capacity, if: :capacity_changed?

  after_find :calculate_occupancy_rates
  attr_reader :week_occupancy_rate, :month_occupancy_rate

  scope :minimum_capacity_of, ->(guests) {
    where('capacity >= ?', guests)
  }

  scope :unavailable_for_period, ->(query_start_date, query_end_date) {
    joins(:reservations).where('start_date < ? AND end_date > ?', query_end_date, query_start_date).uniq
  }

  # Calculates the occupancy rate of the room for the next n_days passed in as first parameter.
  # The default starting date is the day after this method was invoked. This can be overriden by
  # passing a custom date as the second parameter.
  def occupancy_rate_for_the_next(n_days, starting_date = nil)
    return 0 if reservations.blank?

    # Set the observation boundaries for calculating the occupancy rate:
    # Starting tomorrow if no starting date is passed and to n_days-1 after the starting date
    rate_start_date = starting_date || Date.tomorrow
    rate_end_date = rate_start_date.advance(days: n_days - 1)

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
    ((occupied_days / n_days.to_f) * 100).round
  end

  private

  def calculate_occupancy_rates
    @week_occupancy_rate = occupancy_rate_for_the_next(7)
    @month_occupancy_rate = occupancy_rate_for_the_next(30)
  end

  def allowed_to_lower_capacity
    return if capacity.blank?
    return if reservations.blank?
    return if reservations.select { |r| r.number_of_guests > capacity }.empty?

    errors.add(:capacity, :impossible_to_lower,
               message: "Cannot lower room capacity to #{capacity} due to higher number of guests in some reservation")
  end
end
