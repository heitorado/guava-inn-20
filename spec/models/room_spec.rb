require 'rails_helper'

RSpec.describe Room, type: :model do
  it 'validates presence of code' do
    room = Room.new

    expect(room).to_not be_valid
    expect(room).to have_error_on(:code, :blank)
  end

  it 'validates uniqueness of code' do
    Room.create!(code: '101', capacity: 2)

    room = Room.new(code: '101')
    expect(room).to_not be_valid
    expect(room).to have_error_on(:code, :taken)
  end

  it 'validates length of code' do
    room = Room.new(code: '01110011-01110011', capacity: 2, notes: 'crying zeros and I am nearing 111')

    expect(room).to_not be_valid
    expect(room).to have_error_on(:code, :too_long)
  end

  it 'validates presence of capacity' do
    room = Room.new

    expect(room).to_not be_valid
    expect(room).to have_error_on(:capacity, :blank)
  end

  it 'validates that capacity should not be zero' do
    room = Room.new(capacity: 0)

    expect(room).to_not be_valid
    expect(room).to have_error_on(:capacity, :greater_than)
  end

  it 'validates that capacity should not be negative' do
    room = Room.new(capacity: -1)

    expect(room).to_not be_valid
    expect(room).to have_error_on(:capacity, :greater_than)
  end

  it 'validates that capacity should not be greater than ten' do
    room = Room.new(capacity: 11)

    expect(room).to_not be_valid
    expect(room).to have_error_on(:capacity, :less_than_or_equal_to)
  end

  it 'validates length of notes' do
    room = Room.new(
      code: '199',
      capacity: 2,
      # For generating a random string of 513 length
      notes: rand(36**513).to_s(36)
    )

    expect(room).to_not be_valid
    expect(room).to have_error_on(:notes, :too_long)
  end

  describe '#occupancy_rate_for_the_next' do
    it 'always returns an integer number' do
      room = Room.create(code: '101', capacity: 4)
      room.reservations.create(
        start_date: 3.days.ago.to_date,
        end_date: 3.days.from_now.to_date,
        guest_name: 'Manuel',
        number_of_guests: 2
      )

      expect(room.occupancy_rate_for_the_next(7)).to be_an(Integer)
      expect(room.occupancy_rate_for_the_next(30)).to be_an(Integer)
      expect(room.occupancy_rate_for_the_next(159)).to be_an(Integer)
    end

    context 'when there are no reservations for the room' do
      it 'returns zero' do
        room = Room.create(code: '101', capacity: 4)

        expect(room.occupancy_rate_for_the_next(7)).to be_zero
        expect(room.occupancy_rate_for_the_next(30)).to be_zero
        expect(room.occupancy_rate_for_the_next(265)).to be_zero
      end
    end

    describe 'weekly occupancy rate' do
      context 'when there are reservations on the room for the next seven days straight' do
        it 'calculates 100% occupancy rate' do
          room = Room.create(code: '101', capacity: 4)
          room.reservations.create(
            start_date: 3.days.ago.to_date,
            end_date: 3.days.from_now.to_date,
            guest_name: 'Basil Fawlty',
            number_of_guests: 2
          )
          room.reservations.create(
            start_date: 3.days.from_now.to_date,
            end_date: 15.days.from_now.to_date,
            guest_name: 'Polly Sherman',
            number_of_guests: 1
          )

          expect(room.occupancy_rate_for_the_next(7)).to eq(100)
        end
      end

      context 'when there are reservations filling up 5 of the next seven days' do
        it 'calculates 71% occupancy rate' do
          room = Room.create(code: '101', capacity: 4)
          room.reservations.create(
            start_date: Date.tomorrow,
            end_date: 4.days.from_now.to_date,
            guest_name: 'Major Gowen',
            number_of_guests: 1
          )
          room.reservations.create(
            start_date: 5.days.from_now.to_date,
            end_date: 7.days.from_now.to_date,
            guest_name: 'Sybil Fawlty',
            number_of_guests: 3
          )

          expect(room.occupancy_rate_for_the_next(7)).to eq(71)
        end
      end

      context 'when there are reservations filling up 3 of the next seven days' do
        it 'calculates 42% occupancy rate' do
          room = Room.create(code: '101', capacity: 4)
          room.reservations.create(
            start_date: Date.today,
            end_date: 2.days.from_now.to_date,
            guest_name: 'Miss Tibbs',
            number_of_guests: 3
          )
          room.reservations.create(
            start_date: 5.days.from_now.to_date,
            end_date: 7.days.from_now.to_date,
            guest_name: 'Miss Gatsby',
            number_of_guests: 4
          )

          expect(room.occupancy_rate_for_the_next(7)).to eq(42)
        end
      end

      context 'when there are reservations filling up 1 of the next seven days' do
        it 'calculates 14% occupancy rate' do
          room = Room.create(code: '101', capacity: 4)
          room.reservations.create(
            start_date: 4.days.from_now.to_date,
            end_date: 5.days.from_now.to_date,
            guest_name: 'Deise Cristina',
            number_of_guests: 4
          )

          expect(room.occupancy_rate_for_the_next(7)).to eq(14)
        end
      end
    end

    describe 'monthly occupancy rate' do
      context 'when there are reservations on the room for the next thirty days straight' do
        it 'calculates 100% occupancy rate' do
          room = Room.create(code: '101', capacity: 4)
          room.reservations.create(
            start_date: Date.yesterday,
            end_date: 10.days.from_now.to_date,
            guest_name: 'Enzo Thiago',
            number_of_guests: 4
          )
          room.reservations.create(
            start_date: 10.days.from_now.to_date,
            end_date: 20.days.from_now.to_date,
            guest_name: 'Arthur Daniel',
            number_of_guests: 3
          )
          room.reservations.create(
            start_date: 20.days.from_now.to_date,
            end_date: 31.days.from_now.to_date,
            guest_name: 'Bernardo Moraes',
            number_of_guests: 2
          )

          expect(room.occupancy_rate_for_the_next(30)).to eq(100)
        end
      end

      context 'when there are reservations reservations filling up 24 of the next thirty days' do
        it 'calculates 96% occupancy rate' do
          room = Room.create(code: '101', capacity: 4)
          room.reservations.create(
            start_date: Date.tomorrow,
            end_date: 10.days.from_now.to_date,
            guest_name: 'Enzo Thiago',
            number_of_guests: 4
          )
          room.reservations.create(
            start_date: 10.days.from_now.to_date,
            end_date: 15.days.from_now.to_date,
            guest_name: 'Arthur Daniel',
            number_of_guests: 3
          )
          room.reservations.create(
            start_date: 15.days.from_now.to_date,
            end_date: 25.days.from_now.to_date,
            guest_name: 'Bernardo Moraes',
            number_of_guests: 2
          )
          room.reservations.create(
            start_date: 25.days.from_now.to_date,
            end_date: 30.days.from_now.to_date,
            guest_name: 'Carlos Drummond de Andrade',
            number_of_guests: 2
          )

          expect(room.occupancy_rate_for_the_next(30)).to eq(96)
        end
      end

      context 'when there are reservations filling up 24 of the next thirty days' do
        it 'calculates 80% occupancy rate' do
          room = Room.create(code: '101', capacity: 4)
          room.reservations.create(
            start_date: Date.yesterday,
            end_date: 10.days.from_now.to_date,
            guest_name: 'Enzo Carvalho',
            number_of_guests: 1
          )
          room.reservations.create(
            start_date: 12.days.from_now.to_date,
            end_date: 16.days.from_now.to_date,
            guest_name: 'Heitor Carvalho',
            number_of_guests: 1
          )
          room.reservations.create(
            start_date: 20.days.from_now.to_date,
            end_date: 50.days.from_now.to_date,
            guest_name: 'Ayla Reis',
            number_of_guests: 1
          )

          expect(room.occupancy_rate_for_the_next(30)).to eq(80)
        end
      end

      context 'when there are reservations filling up 15 of the next thirty days' do
        it 'calculates 50% occupancy rate' do
          room = Room.create(code: '101', capacity: 4)
          room.reservations.create(
            start_date: Date.today,
            end_date: 10.days.from_now.to_date,
            guest_name: 'Rosa Gomes',
            number_of_guests: 2
          )
          room.reservations.create(
            start_date: 12.days.from_now.to_date,
            end_date: 16.days.from_now.to_date,
            guest_name: 'Ailton Reis',
            number_of_guests: 3
          )

          room.reservations.create(
            start_date: 29.days.from_now.to_date,
            end_date: 31.days.from_now.to_date,
            guest_name: 'Clarice Lispector',
            number_of_guests: 3
          )

          expect(room.occupancy_rate_for_the_next(30)).to eq(50)
        end
      end

      context 'when there are reservations filling up 12 of the next thirty days' do
        it 'calculates 40% occupancy rate' do
          room = Room.create(code: '101', capacity: 4)
          room.reservations.create(
            start_date: Date.today,
            end_date: 10.days.from_now.to_date,
            guest_name: 'Rosa Gomes',
            number_of_guests: 2
          )
          room.reservations.create(
            start_date: 12.days.from_now.to_date,
            end_date: 15.days.from_now.to_date,
            guest_name: 'Cedrico Diggory',
            number_of_guests: 3
          )

          expect(room.occupancy_rate_for_the_next(30)).to eq(40)
        end
      end

      context 'when there are reservations filling up 9 of the next thirty days' do
        it 'calculates 30% occupancy rate' do
          room = Room.create(code: '101', capacity: 4)
          room.reservations.create(
            start_date: Date.tomorrow,
            end_date: 4.days.from_now.to_date,
            guest_name: 'Paulo Moreira',
            number_of_guests: 2
          )

          room.reservations.create(
            start_date: 5.days.from_now.to_date,
            end_date: 8.days.from_now.to_date,
            guest_name: 'Nilce Almeida',
            number_of_guests: 2
          )

          room.reservations.create(
            start_date: 9.days.from_now.to_date,
            end_date: 12.days.from_now.to_date,
            guest_name: 'Leon Costa',
            number_of_guests: 2
          )

          expect(room.occupancy_rate_for_the_next(30)).to eq(30)
        end
      end

      context 'when there are reservations filling up 3 of the next thirty days' do
        it 'calculates 10% occupancy rate' do
          room = Room.create(code: '101', capacity: 4)
          room.reservations.create(
            start_date: Date.today,
            end_date: 3.days.from_now.to_date,
            guest_name: 'Harry Potter',
            number_of_guests: 2
          )

          room.reservations.create(
            start_date: 9.days.from_now.to_date,
            end_date: 10.days.from_now.to_date,
            guest_name: 'Hermione Granger',
            number_of_guests: 2
          )

          expect(room.occupancy_rate_for_the_next(30)).to eq(10)
        end
      end

      context 'when there are reservations filling up 1 of the next thirty days' do
        it 'calculates 3% occupancy rate' do
          room = Room.create(code: '101', capacity: 4)
          room.reservations.create(
            start_date: Date.yesterday,
            end_date: Date.tomorrow,
            guest_name: 'Enzo Carvalho',
            number_of_guests: 1
          )

          room.reservations.create(
            start_date: 30.days.from_now.to_date,
            end_date: 50.days.from_now.to_date,
            guest_name: 'Heitor Carvalho',
            number_of_guests: 1
          )

          expect(room.occupancy_rate_for_the_next(30)).to eq(3)
        end
      end
    end
  end
end
