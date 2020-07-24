class Reservation < ApplicationRecord
  belongs_to :room

  validates_presence_of :start_date, :end_date, :guest_name, :number_of_guests
  validates_length_of :guest_name, maximum: 256
  validates_numericality_of :number_of_guests, greater_than: 0, less_than_or_equal_to: 10
  validates :guest_email, format: { with: /\A(.+)@(.+)\z/, message: 'Invalid email' },
                          length: { maximum: 128 },
                          allow_blank: true
  validate :start_date_is_before_end_date
  validate :chosen_dates_do_not_overlap_with_existent_reservations
  validate :number_of_guests_does_not_exceed_room_capacity

  def duration
    if start_date.present? && end_date.present? && end_date > start_date
      (end_date - start_date).to_i
    end
  end

  def code
    if id.present? && room&.code.present?
      formatted_id = '%02d' % id
      "#{room.code}-#{formatted_id}"
    end
  end

  private

  def start_date_is_before_end_date
    if start_date.present? && end_date.present? && start_date >= end_date
      errors.add(:base, :invalid_dates, message: 'The start date should be before the end date')
    end
  end

  def chosen_dates_do_not_overlap_with_existent_reservations
    return if room.blank?
    return if Reservation.where('start_date < ? AND end_date > ? AND room_id = ?', end_date, start_date, room.id).empty?

    errors.add(:base, :invalid_dates, message: 'This reservation overlaps with one or more other reservations')
  end

  def number_of_guests_does_not_exceed_room_capacity
    return if room.blank? || number_of_guests.blank?
    return if number_of_guests <= room.capacity

    errors.add(:number_of_guests, :guest_overflow, message: 'The number of guests does not fit in this room')
  end
end
