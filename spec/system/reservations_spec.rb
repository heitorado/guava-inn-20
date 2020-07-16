require 'rails_helper'

RSpec.describe 'Reservations', type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  describe 'searching' do
    before do
      @room = Room.create!(code: '101', capacity: 2)
      @room.reservations.create(
        id: 1,
        start_date: '2020-08-01',
        end_date: '2020-08-15',
        guest_name: 'Heitor Carvalho',
        number_of_guests: 1
      )
      @room.reservations.create(
        id: 2,
        start_date: '2020-08-15',
        end_date: '2020-08-30',
        guest_name: 'Carolina dos Anjos',
        number_of_guests: 2
      )

      Room.create!(code: '102', capacity: 5)
      Room.create!(code: '103', capacity: 3)
      Room.create!(code: '104', capacity: 1)
      Room.create!(code: '105', capacity: 4)

      visit search_reservations_path
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
        fill_in 'start_date', with: 7.days.ago.strftime('%m/%d/%Y')
        fill_in 'end_date', with: 7.days.from_now.strftime('%m/%d/%Y')
        select '4', from: 'number_of_guests'
        click_button 'commit'
      end

      expect(page).to have_content('Available Rooms')

      within('table') do
        within('tbody tr:first-child') do
          expect(page).to have_content('102')
          expect(page).to have_content('5 people')
        end

        within('tbody tr:last-child') do
          expect(page).to have_content('105')
          expect(page).to have_content('4 people')
        end
      end
    end

    it 'shows all the rooms that have no overlapping reservations with the provided date interval' do
      expect(page).to have_content('New Reservation')

      within('form') do
        fill_in 'start_date', with: '08/05/2020'
        fill_in 'end_date', with: '08/05/2020'
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
        end
      end
    end
  end
end
