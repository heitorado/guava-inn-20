require 'rails_helper'

RSpec.describe 'Reservations', type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  describe 'searching' do
    before do
      @room = Room.create!(code: '101', capacity: 2)
      @room.reservations.create(
        start_date: '2020-08-01',
        end_date: '2020-08-15',
        guest_name: 'Heitor Carvalho',
        number_of_guests: 1
      )
      @room.reservations.create(
        start_date: '2020-08-15',
        end_date: '2020-08-30',
        guest_name: 'Carolina dos Anjos',
        number_of_guests: 2
      )

      Room.create!(code: '102', capacity: 5)
      Room.create!(code: '103', capacity: 3)
      Room.create!(code: '104', capacity: 1)
      Room.create!(code: '105', capacity: 4)

      @room = Room.create!(code: '106', capacity: 6)
      @room.reservations.create(
        start_date: '2020-08-20',
        end_date: '2020-08-24',
        guest_name: 'Diego Costa',
        number_of_guests: 2
      )

      visit search_reservations_path
    end

    context 'when start_date is after end_date' do
      before do
        expect(page).to have_content('New Reservation')

        within('form') do
          fill_in 'start_date', with: 7.days.from_now.strftime('%m/%d/%Y')
          fill_in 'end_date', with: 7.days.ago.strftime('%m/%d/%Y')
          select '2', from: 'number_of_guests'
          click_button 'commit'
        end
      end

      it 'shows no results' do
        expect(page).to have_no_content('Available Rooms')
        expect(page).to have_no_content('101')
        expect(page).to have_no_content('102')
        expect(page).to have_no_content('103')
        expect(page).to have_no_content('104')
        expect(page).to have_no_content('105')
        expect(page).to have_no_content('106')
      end

      it 'returns an error message' do
        expect(page).to have_content("the 'From' date must happen before the 'To' date")
      end
    end

    it 'allows users to search for available rooms with a given capacity in a period' do
      expect(page).to have_content('New Reservation')

      within('form') do
        fill_in 'start_date', with: 7.days.ago.strftime('%m/%d/%Y')
        fill_in 'end_date', with: 7.days.from_now.strftime('%m/%d/%Y')
        select '2', from: 'number_of_guests'
        click_button 'commit'
      end

      expect(page).to have_content('Available Rooms')
    end

    it 'shows only the rooms that have at least the capacity specified' do
      expect(page).to have_content('New Reservation')

      within('form') do
        fill_in 'start_date', with: '07/01/2020'
        fill_in 'end_date', with: '07/10/2020'
        select '4', from: 'number_of_guests'
        click_button 'commit'
      end

      expect(page).to have_content('Available Rooms')

      within('table') do
        within('tbody') do
          expect(page).to have_no_content('101')
          expect(page).to have_content('102')
          expect(page).to have_no_content('103')
          expect(page).to have_no_content('104')
          expect(page).to have_content('105')
          expect(page).to have_content('106')
        end
      end
    end

    it 'shows all the rooms that have no overlapping reservations with the provided date interval' do
      expect(page).to have_content('New Reservation')

      within('form') do
        fill_in 'start_date', with: '08/07/2020'
        fill_in 'end_date', with: '08/20/2020'
        select '1', from: 'number_of_guests'
        click_button 'commit'
      end

      expect(page).to have_content('Available Rooms')

      within('table') do
        within('tbody') do
          expect(page).to have_no_content('101')
          expect(page).to have_content('102')
          expect(page).to have_content('103')
          expect(page).to have_content('104')
          expect(page).to have_content('105')
          expect(page).to have_content('106')
        end
      end
    end

    context 'when there are no rooms available' do
      it "shows the message 'There are no available rooms for the selected filters'" do
        expect(page).to have_content('New Reservation')

        within('form') do
          fill_in 'start_date', with: '08/14/2020'
          fill_in 'end_date', with: '08/22/2020'
          select '6', from: 'number_of_guests'
          click_button 'commit'
        end

        expect(page).to have_content('Available Rooms')

        within('table') do
          within('tbody') do
            expect(page).to have_content('There are no available rooms for the selected filters')
            expect(page).to have_no_content('101')
            expect(page).to have_no_content('102')
            expect(page).to have_no_content('103')
            expect(page).to have_no_content('104')
            expect(page).to have_no_content('105')
            expect(page).to have_no_content('106')
          end
        end
      end
    end
  end
end
