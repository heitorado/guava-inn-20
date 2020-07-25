require 'rails_helper'

RSpec.describe 'Reservations', type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  describe 'searching' do
    before do
      create(:room, code: '101', capacity: 2, with_reservations: [
               { start_date: '2020-08-01', end_date: '2020-08-15' }
             ])

      create(:room, code: '102', capacity: 5)
      create(:room, code: '103', capacity: 3)
      create(:room, code: '104', capacity: 1)
      create(:room, code: '105', capacity: 4)

      create(:room, code: '106', capacity: 6, with_reservations: [
               { start_date: '2020-08-20', end_date: '2020-08-24' }
             ])

      visit search_reservations_path
    end

    it 'has a link to go back to the listing' do
      expect(page).to have_link('Back', href: rooms_path)
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
  end

  describe 'new reservation' do
    before do
      @room = create(:room, code: '101', capacity: 3)

      visit search_reservations_path

      within('form') do
        fill_in 'start_date', with: '08/14/2020'
        fill_in 'end_date', with: '08/22/2020'
        select '2', from: 'number_of_guests'
        click_button 'commit'
      end

      @search_url = URI.parse(current_url).request_uri

      within('table tbody tr:first-child') do
        click_link 'Create Reservation'
      end
    end

    it 'allows users to create a new reservation with the same parameters specified on the search' do
      expect(page).to have_content("New Reservation for Room #{@room.code}")
      expect(page).to have_selector('input#reservation_start_date[value="2020-08-14"]')
      expect(page).to have_selector('input#reservation_end_date[value="2020-08-22"]')
      expect(page).to have_selector('select#reservation_number_of_guests option[selected][value="2"]')

      fill_in 'reservation_guest_name', with: 'Heitor Carvalho'
      click_button 'commit'

      expect(page).to have_content('was successfully created.')
      expect(page).to have_content('101-')
      expect(page).to have_content('2020-08-14 to 2020-08-22')
      expect(page).to have_content('Heitor Carvalho')
    end

    it 'shows only options on number of guests up to the room maximum capacity' do
      expect(page).to have_css('select#reservation_number_of_guests option', count: @room.capacity)
      expect(page).to have_selector('select#reservation_number_of_guests option[value="1"]')
      expect(page).to have_selector('select#reservation_number_of_guests option[value="2"]')
      expect(page).to have_selector('select#reservation_number_of_guests option[value="3"]')
    end

    it 'has a link to go back to the search' do
      expect(page).to have_link('Back', href: @search_url)
    end

    it 'shows an error message when there is a validation error' do
      click_button 'commit'
      expect(page).to have_content("can't be blank")
    end

    context 'when guest email field is informed' do
      before do
        fill_in 'reservation_guest_name', with: 'Heitor Carvalho'
        fill_in 'reservation_guest_email', with: 'heitorcarvalho@example.com'
        click_button 'commit'
      end

      it 'creates the reservation successfully' do
        expect(page).to have_content('was successfully created.')
        expect(page).to have_content('Heitor Carvalho')
      end

      it 'sends a confirmation email' do
        expect(page).to have_content('was successfully created.')
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries.first.to).to include('heitorcarvalho@example.com')
      end
    end

    context 'when there is more than one failed creation attempt in succession' do
      it 'has a link that goes back to the last search made' do
        click_button 'commit'
        click_button 'commit'
        click_button 'commit'

        expect(page).to have_link('Back', href: @search_url)
      end
    end
  end
end
