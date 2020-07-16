require 'rails_helper'

RSpec.describe Reservation, type: :model do
  it 'validates presence of room' do
    reservation = Reservation.new

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:room, :blank)
  end

  it 'validates presence of start_date' do
    reservation = Reservation.new

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:start_date, :blank)
  end

  it 'validates presence of end_date' do
    reservation = Reservation.new

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:end_date, :blank)
  end

  it 'validates presence of guest_name' do
    reservation = Reservation.new

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:guest_name, :blank)
  end

  it 'validates presence of number_of_guests' do
    reservation = Reservation.new

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:number_of_guests, :blank)
  end

  it 'validates that number_of_guests should not be zero' do
    reservation = Reservation.new(number_of_guests: 0)

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:number_of_guests, :greater_than)
  end

  it 'validates that number_of_guests should not be negative' do
    reservation = Reservation.new(number_of_guests: -1)

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:number_of_guests, :greater_than)
  end

  it 'validates that number_of_guests should not be greater than ten' do
    reservation = Reservation.new(number_of_guests: 11)

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:number_of_guests, :less_than_or_equal_to)
  end

  it 'validates that number_of_guests does not exceed room.capacity' do
    room = Room.new(capacity: 2)
    reservation = room.reservations.new(number_of_guests: 4)

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:number_of_guests, :guest_overflow)
  end

  it 'validates that start_date is before end_date' do
    reservation = Reservation.new(start_date: '2020-08-02', end_date: '2020-08-01')

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:base, :invalid_dates)
  end

  it 'validates that start_date is not equal to end_date' do
    reservation = Reservation.new(start_date: '2020-08-02', end_date: '2020-08-02')

    expect(reservation).to_not be_valid
    expect(reservation).to have_error_on(:base, :invalid_dates)
  end

  it 'validates that a new reservation cannot overlap with any other reservation for the same room' do
    room = Room.create!(code: '101', capacity: '4')
    room.reservations.create(
      start_date: '2020-08-10',
      end_date: '2020-08-24',
      guest_name: 'Victor Siqueira',
      number_of_guests: 3
    )

    reservation1 = room.reservations.new(
      start_date: '2020-08-01',
      end_date: '2020-08-15',
      guest_name: 'Diego Costa',
      number_of_guests: 2
    )

    reservation2 = room.reservations.new(
      start_date: '2020-08-12',
      end_date: '2020-08-23',
      guest_name: 'Ricardo Lima',
      number_of_guests: 4
    )

    reservation3 = room.reservations.new(
      start_date: '2020-08-20',
      end_date: '2020-08-30',
      guest_name: 'Alisson Freitas',
      number_of_guests: 1
    )

    expect(reservation1).to_not be_valid
    expect(reservation2).to_not be_valid
    expect(reservation3).to_not be_valid
    expect(reservation1).to have_error_on(:base, :invalid_dates)
    expect(reservation2).to have_error_on(:base, :invalid_dates)
    expect(reservation3).to have_error_on(:base, :invalid_dates)
  end

  it 'validates that a reservation can start at the same day another one ends' do
    room = Room.create!(code: '101', capacity: '4')
    room.reservations.create(
      start_date: '2020-08-10',
      end_date: '2020-08-24',
      guest_name: 'Juliano Vaz',
      number_of_guests: 3
    )

    reservation = room.reservations.new(
      start_date: '2020-08-24',
      end_date: '2020-09-05',
      guest_name: 'Lucas Barros',
      number_of_guests: 2
    )

    expect(reservation).to be_valid
  end

  it 'validates that a reservation can end at the same day another one starts' do
    room = Room.create!(code: '101', capacity: '4')
    room.reservations.create(
      start_date: '2020-10-05',
      end_date: '2020-10-12',
      guest_name: 'Paulo Jorge',
      number_of_guests: 3
    )

    reservation = room.reservations.new(
      start_date: '2020-09-24',
      end_date: '2020-10-05',
      guest_name: 'Letícia Souza',
      number_of_guests: 2
    )

    expect(reservation).to be_valid
  end

  describe '#duration' do
    it 'returns the number of nights for the reservation' do
      reservation = Reservation.new(start_date: '2020-08-01', end_date: '2020-08-05')

      expect(reservation.duration).to eq(4)
    end

    context 'when start or end_date is blank' do
      it 'returns nil' do
        reservation = Reservation.new(start_date: '2020-08-01', end_date: nil)

        expect(reservation.duration).to be_nil
      end
    end

    context 'when the start_date is equal to or after the end_date' do
      it 'returns nil' do
        reservation = Reservation.new(start_date: '2020-08-01', end_date: '2020-07-31')

        expect(reservation.duration).to be_nil
      end
    end
  end

  describe '#code' do
    it 'returns the room code and two-digit reservation id' do
      room = Room.new(code: '101')
      reservation = Reservation.new(id: 2, room: room)

      expect(reservation.code).to eq('101-02')
    end

    context 'when the room is not present' do
      it 'returns nil' do
        reservation = Reservation.new(room: nil)

        expect(reservation.code).to be_nil
      end
    end

    context 'when the room is present but does not have code' do
      it 'returns nil' do
        room = Room.new(code: nil)
        reservation = Reservation.new(id: 2, room: room)

        expect(reservation.code).to be_nil
      end
    end

    context 'when the reservation does not have id' do
      it 'returns nil' do
        room = Room.new(code: '101')
        reservation = Reservation.new(id: nil, room: room)

        expect(reservation.code).to be_nil
      end
    end

    context 'when the reservation id is greater than 99' do
      it 'returns a code with the second part having more than two digits' do
        room = Room.new(code: '101')
        reservation = Reservation.new(id: 100, room: room)

        expect(reservation.code).to eq('101-100')
      end
    end
  end
end
