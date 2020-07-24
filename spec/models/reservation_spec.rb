require 'rails_helper'

RSpec.describe Reservation, type: :model do
  it 'validates presence of room' do
    reservation = build(:reservation, room: nil)

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:room, :blank)
  end

  it 'validates presence of start_date' do
    reservation = build(:reservation, start_date: nil)

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:start_date, :blank)
  end

  it 'validates presence of end_date' do
    reservation = build(:reservation, end_date: nil)

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:end_date, :blank)
  end

  it 'validates that start_date is before end_date' do
    reservation = build(:reservation, start_date: '2020-08-02', end_date: '2020-08-01')

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:base, :invalid_dates)
  end

  it 'validates that start_date is not equal to end_date' do
    reservation = build(:reservation, start_date: '2020-08-02', end_date: '2020-08-02')

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:base, :invalid_dates)
  end

  it 'validates that a new reservation does not overlap with another reservation for the same room' do
    room = create(:room, capacity: 4, with_reservations: [
                    { start_date: '2020-08-10', end_date: '2020-08-24' }
                  ])
    reservation1 = build(:reservation, start_date: '2020-08-01', end_date: '2020-08-15', room: room)
    reservation2 = build(:reservation, start_date: '2020-08-12', end_date: '2020-08-23', room: room)
    reservation3 = build(:reservation, start_date: '2020-08-20', end_date: '2020-08-30', room: room)

    expect(reservation1).to_not be_valid
    expect(reservation1).to have_error_on(:base, :invalid_dates)

    expect(reservation2).to_not be_valid
    expect(reservation2).to have_error_on(:base, :invalid_dates)

    expect(reservation3).to_not be_valid
    expect(reservation3).to have_error_on(:base, :invalid_dates)
  end

  it 'validates that a reservation can start at the same day another one ends' do
    room = create(:room, capacity: 4, with_reservations: [
                    { start_date: '2020-08-10', end_date: '2020-08-24' }
                  ])

    reservation = build(:reservation, start_date: '2020-08-24', end_date: '2020-09-05', room: room)

    expect(reservation).to be_valid
  end

  it 'validates that a reservation can end at the same day another one starts' do
    room = create(:room, capacity: 4, with_reservations: [
                    { start_date: '2020-10-05', end_date: '2020-10-12' }
                  ])

    reservation = build(:reservation, start_date: '2020-09-24', end_date: '2020-10-05', room: room)

    expect(reservation).to be_valid
  end

  it 'validates presence of guest_name' do
    reservation = build(:reservation, guest_name: nil)

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:guest_name, :blank)
  end

  it 'validates length of guest_name' do
    reservation = build(:reservation, guest_name: (0..256).map { [*('A'..'z')].sample }.join)

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:guest_name, :too_long)
  end

  it 'validates format of email' do
    reservation = build(:reservation, guest_email: 'not_a_valid_email.com')

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:guest_email, :invalid)
  end

  it 'validates length of email' do
    reservation = build(:reservation, guest_email: "#{(0..128).map { [*('A'..'z')].sample }.join}@mail.com")

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:guest_email, :too_long)
  end

  it 'validates presence of number_of_guests' do
    reservation = build(:reservation, number_of_guests: nil)

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:number_of_guests, :blank)
  end

  it 'validates that number_of_guests should not be zero' do
    reservation = build(:reservation, number_of_guests: 0)

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:number_of_guests, :greater_than)
  end

  it 'validates that number_of_guests should not be negative' do
    reservation = build(:reservation, number_of_guests: -1)

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:number_of_guests, :greater_than)
  end

  it 'validates that number_of_guests should not be greater than ten' do
    reservation = build(:reservation, number_of_guests: 11)

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:number_of_guests, :less_than_or_equal_to)
  end

  it 'validates that number_of_guests does not exceed room.capacity' do
    reservation = build(:reservation, number_of_guests: 5, on_room: {
                          capacity: 3
                        })

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:number_of_guests, :guest_overflow)
  end

  describe '#duration' do
    it 'returns the number of nights for the reservation' do
      reservation = build(:reservation, start_date: '2020-08-01', end_date: '2020-08-05')

      expect(reservation.duration).to eq(4)
    end

    context 'when start or end_date is blank' do
      it 'returns nil' do
        reservation = build(:reservation, start_date: '2020-08-01', end_date: nil)

        expect(reservation.duration).to be_nil
      end
    end

    context 'when the start_date is equal to or after the end_date' do
      it 'returns nil' do
        reservation = build(:reservation, start_date: '2020-08-01', end_date: '2020-07-31')

        expect(reservation.duration).to be_nil
      end
    end
  end

  describe '#code' do
    it 'returns the room code and two-digit reservation id' do
      reservation = build(:reservation, id: 2, on_room: { code: '101' })

      expect(reservation.code).to eq('101-02')
    end

    context 'when the room is not present' do
      it 'returns nil' do
        reservation = build(:reservation, room: nil)

        expect(reservation.code).to be_nil
      end
    end

    context 'when the room is present but does not have code' do
      it 'returns nil' do
        reservation = build(:reservation, id: 2, on_room: { code: nil })

        expect(reservation.code).to be_nil
      end
    end

    context 'when the reservation does not have id' do
      it 'returns nil' do
        reservation = build(:reservation, id: nil, on_room: { code: '101' })

        expect(reservation.code).to be_nil
      end
    end

    context 'when the reservation id is greater than 99' do
      it 'returns a code with the second part having more than two digits' do
        reservation = build(:reservation, id: 100, on_room: { code: '101' })

        expect(reservation.code).to eq('101-100')
      end
    end
  end
end
