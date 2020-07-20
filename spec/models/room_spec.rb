require 'rails_helper'

RSpec.describe Room, type: :model do
  it 'validates presence of code' do
    room = build(:room, code: nil)

    expect(room).to_not be_valid
    expect(room).to have_error_on(:code, :blank)
  end

  it 'validates uniqueness of code' do
    create(:room, code: '101')
    room = build(:room, code: '101')

    expect(room).to_not be_valid
    expect(room).to have_error_on(:code, :taken)
  end

  it 'validates length of code' do
    room = build(:room, code: '01110011-01110011')

    expect(room).to_not be_valid
    expect(room).to have_error_on(:code, :too_long)
  end

  it 'validates presence of capacity' do
    room = build(:room, capacity: nil)

    expect(room).to_not be_valid
    expect(room).to have_error_on(:capacity, :blank)
  end

  it 'validates that capacity should not be zero' do
    room = build(:room, capacity: 0)

    expect(room).to_not be_valid
    expect(room).to have_error_on(:capacity, :greater_than)
  end

  it 'validates that capacity should not be negative' do
    room = build(:room, capacity: -1)

    expect(room).to_not be_valid
    expect(room).to have_error_on(:capacity, :greater_than)
  end

  it 'validates that capacity should not be greater than ten' do
    room = build(:room, capacity: 11)

    expect(room).to_not be_valid
    expect(room).to have_error_on(:capacity, :less_than_or_equal_to)
  end

  it 'validates length of notes' do
    # For generating a random string of length 513
    room = build(:room, notes: (0..512).map { [*('A'..'z')].sample }.join)

    expect(room).to_not be_valid
    expect(room).to have_error_on(:notes, :too_long)
  end

  describe '#occupancy_rate_for_the_next' do
    it 'always returns an integer number' do
      room = create(:room, with_random_reservation: true)

      expect(room.occupancy_rate_for_the_next(7)).to be_an(Integer)
      expect(room.occupancy_rate_for_the_next(30)).to be_an(Integer)
      expect(room.occupancy_rate_for_the_next(159)).to be_an(Integer)
    end

    context 'when there are no reservations for the room' do
      it 'returns zero' do
        room = create(:room)

        expect(room.occupancy_rate_for_the_next(7)).to be_zero
        expect(room.occupancy_rate_for_the_next(30)).to be_zero
        expect(room.occupancy_rate_for_the_next(265)).to be_zero
      end
    end

    describe 'weekly occupancy rate' do
      context 'when there are reservations on the room for the next seven days straight' do
        it 'calculates 100% occupancy rate' do
          room = create(:room, with_reservations: [
                          { start_date: 3.days.ago, end_date: 3.days.from_now },
                          { start_date: 3.days.from_now, end_date: 15.days.from_now }
                        ])

          expect(room.occupancy_rate_for_the_next(7)).to eq(100)
        end
      end

      context 'when there are reservations filling up 5 of the next seven days' do
        it 'calculates 71% occupancy rate' do
          room = create(:room, with_reservations: [
                          { start_date: Date.tomorrow, end_date: 4.days.from_now },
                          { start_date: 5.days.from_now, end_date: 7.days.from_now }
                        ])

          expect(room.occupancy_rate_for_the_next(7)).to eq(71)
        end
      end

      context 'when there are reservations filling up 3 of the next seven days' do
        it 'calculates 43% occupancy rate' do
          room = create(:room, with_reservations: [
                          { start_date: Date.today, end_date: 2.days.from_now },
                          { start_date: 5.days.from_now, end_date: 7.days.from_now }
                        ])

          expect(room.occupancy_rate_for_the_next(7)).to eq(43)
        end
      end

      context 'when there is a reservation filling up 1 of the next seven days' do
        it 'calculates 14% occupancy rate' do
          room = create(:room, with_reservations: [
                          { start_date: 4.days.from_now, end_date: 5.days.from_now }
                        ])

          expect(room.occupancy_rate_for_the_next(7)).to eq(14)
        end
      end
    end

    describe 'monthly occupancy rate' do
      context 'when there are reservations on the room for the next thirty days straight' do
        it 'calculates 100% occupancy rate' do
          room = create(:room, with_reservations: [
                          { start_date: Date.yesterday, end_date: 10.days.from_now },
                          { start_date: 10.days.from_now, end_date: 20.days.from_now },
                          { start_date: 20.days.from_now, end_date: 31.days.from_now }
                        ])

          expect(room.occupancy_rate_for_the_next(30)).to eq(100)
        end
      end

      context 'when there are reservations reservations filling up 24 of the next thirty days' do
        it 'calculates 97% occupancy rate' do
          room = create(:room, with_reservations: [
                          { start_date: Date.tomorrow, end_date: 10.days.from_now },
                          { start_date: 10.days.from_now, end_date: 15.days.from_now },
                          { start_date: 15.days.from_now, end_date: 25.days.from_now },
                          { start_date: 25.days.from_now, end_date: 30.days.from_now }
                        ])

          expect(room.occupancy_rate_for_the_next(30)).to eq(97)
        end
      end

      context 'when there are reservations filling up 24 of the next thirty days' do
        it 'calculates 80% occupancy rate' do
          room = create(:room, with_reservations: [
                          { start_date: Date.yesterday, end_date: 10.days.from_now },
                          { start_date: 12.days.from_now, end_date: 16.days.from_now },
                          { start_date: 20.days.from_now, end_date: 50.days.from_now }
                        ])

          expect(room.occupancy_rate_for_the_next(30)).to eq(80)
        end
      end

      context 'when there are reservations filling up 15 of the next thirty days' do
        it 'calculates 50% occupancy rate' do
          room = create(:room, with_reservations: [
                          { start_date: Date.today, end_date: 10.days.from_now },
                          { start_date: 12.days.from_now, end_date: 16.days.from_now },
                          { start_date: 29.days.from_now, end_date: 31.days.from_now }
                        ])

          expect(room.occupancy_rate_for_the_next(30)).to eq(50)
        end
      end

      context 'when there are reservations filling up 12 of the next thirty days' do
        it 'calculates 40% occupancy rate' do
          room = create(:room, with_reservations: [
                          { start_date: Date.today, end_date: 10.days.from_now },
                          { start_date: 12.days.from_now, end_date: 15.days.from_now }
                        ])

          expect(room.occupancy_rate_for_the_next(30)).to eq(40)
        end
      end

      context 'when there are reservations filling up 9 of the next thirty days' do
        it 'calculates 30% occupancy rate' do
          room = create(:room, with_reservations: [
                          { start_date: Date.tomorrow, end_date: 4.days.from_now },
                          { start_date: 5.days.from_now, end_date: 8.days.from_now },
                          { start_date: 9.days.from_now, end_date: 12.days.from_now }
                        ])

          expect(room.occupancy_rate_for_the_next(30)).to eq(30)
        end
      end

      context 'when there are reservations filling up 3 of the next thirty days' do
        it 'calculates 10% occupancy rate' do
          room = create(:room, with_reservations: [
                          { start_date: Date.today, end_date: 3.days.from_now },
                          { start_date: 9.days.from_now, end_date: 10.days.from_now }
                        ])

          expect(room.occupancy_rate_for_the_next(30)).to eq(10)
        end
      end

      context 'when there are reservations filling up 1 of the next thirty days' do
        it 'calculates 3% occupancy rate' do
          room = create(:room, with_reservations: [
                          { start_date: Date.yesterday, end_date: Date.tomorrow },
                          { start_date: 30.days.from_now, end_date: 50.days.from_now }
                        ])

          expect(room.occupancy_rate_for_the_next(30)).to eq(3)
        end
      end
    end
  end
end
