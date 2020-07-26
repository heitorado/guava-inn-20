require 'rails_helper'

RSpec.describe 'Rooms', type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  describe 'listing' do
    before do
      create(:room, code: '101', capacity: 1, with_reservations: [
               { start_date: Date.yesterday, end_date: 5.days.from_now }
             ])
      create(:room, code: '102', capacity: 5, with_reservations: [
               { start_date: 12.days.from_now, end_date: 22.days.from_now }
             ])
      create(:room, code: '103', capacity: 3, with_reservations: [
               { start_date: Date.tomorrow, end_date: 7.days.from_now },
               { start_date: 8.days.from_now, end_date: 17.days.from_now }
             ])
    end

    it 'shows the total number of rooms' do
      visit rooms_path

      expect(page).to have_content("#{Room.count} Rooms registered")
    end

    it 'shows all rooms in the system with their respective details' do
      visit rooms_path

      expect(page).to have_content('Rooms')

      within('#week-global-occupancy') do
        expect(page).to have_content('47%')
      end

      within('#month-global-occupancy') do
        expect(page).to have_content('32%')
      end

      within('table') do
        within('thead') do
          expect(page).to have_content('Code')
          expect(page).to have_content('Capacity')
          expect(page).to have_content('Occupancy')
          expect(page).to have_content('Actions')
        end

        within('tbody tr:first-child') do
          expect(page).to have_content('101')
          expect(page).to have_content('1 person')
          expect(page).to have_content('57%')
          expect(page).to have_content('13%')
          expect(page).to have_link(href: room_path(Room.first.id))
          expect(page).to have_link(href: edit_room_path(Room.first.id))
          expect(page).to have_selector("a[data-method=delete][href=\"#{room_path(Room.first.id)}\"]")
        end

        within('tbody tr:nth-child(2)') do
          expect(page).to have_content('102')
          expect(page).to have_content('5 people')
          expect(page).to have_content('0%')
          expect(page).to have_content('33%')
          expect(page).to have_link(href: room_path(Room.second.id))
          expect(page).to have_link(href: edit_room_path(Room.second.id))
          expect(page).to have_selector("a[data-method=delete][href=\"#{room_path(Room.second.id)}\"]")
        end

        within('tbody tr:last-child') do
          expect(page).to have_content('103')
          expect(page).to have_content('3 people')
          expect(page).to have_content('86%')
          expect(page).to have_content('50%')
          expect(page).to have_link(href: room_path(Room.last.id))
          expect(page).to have_link(href: edit_room_path(Room.last.id))
          expect(page).to have_selector("a[data-method=delete][href=\"#{room_path(Room.last.id)}\"]")
        end
      end
    end

    it 'allows users to delete a room' do
      visit rooms_path

      expect(page).to have_selector('table tbody tr', count: 3)

      within('table tbody tr:first-child') do
        accept_alert do
          find(:css, "a[data-method=delete][href=\"#{room_path(Room.first.id)}\"]").click
        end
      end

      expect(page).to have_selector('table tbody tr', count: 2)
      expect(page).to have_content('Room was successfully destroyed')
    end

    it 'has a link to create a new room' do
      visit rooms_path

      expect(page).to have_link('New Room', href: new_room_path)
    end

    it 'has a link to create a new reservation' do
      visit rooms_path

      expect(page).to have_link('New Reservation', href: search_reservations_path)
    end

    context 'when there are no rooms' do
      before do
        Room.destroy_all
        visit rooms_path
      end

      it 'shows zero percent global week occupancy rate' do
        within('#week-global-occupancy') do
          expect(page).to have_content('0%')
        end
      end

      it 'shows zero percent global month occupancy rate' do
        within('#month-global-occupancy') do
          expect(page).to have_content('0%')
        end
      end

      it 'shows an empty listing' do
        within('table') do
          expect(page).to have_content('There are no rooms')
        end
      end
    end
  end

  describe 'new room' do
    it 'allows users to create a new room' do
      visit new_room_path

      expect(page).to have_content('New Room')

      fill_in 'Code', with: '204'
      select '3', from: 'Capacity'
      click_on 'Create Room'

      expect(page).to have_current_path(room_path(Room.last.id))
      expect(page).to have_content('Room was successfully created')
    end

    it 'shows an error message when there is a validation error' do
      visit new_room_path
      click_on 'Create Room'

      expect(page).to have_content("can't be blank")
    end

    it 'has a link to go back to the listing' do
      visit new_room_path

      expect(page).to have_link('Back', href: rooms_path)
    end
  end

  describe 'show room' do
    before do
      @room = create(:room, code: '147', capacity: 4, notes: 'Sparkling clean', with_reservations: [
                       { id: 1,
                         start_date: Date.tomorrow,
                         end_date: 9.days.from_now,
                         guest_name: 'João Santana',
                         guest_email: 'joaosantana@example.com',
                         number_of_guests: 1 },
                       { id: 2,
                         start_date: 10.days.from_now,
                         end_date: 11.days.from_now,
                         guest_name: 'Carolina dos Anjos',
                         number_of_guests: 3 }
                     ])
    end

    it 'shows the details of a room including its reservations' do
      visit room_path(@room.id)

      expect(page).to have_content('Room 147')
      expect(page).to have_content('Code: 147')
      expect(page).to have_content('Capacity: 4')
      expect(page).to have_content('Occupancy Rate (Week): 100%')
      expect(page).to have_content('Occupancy Rate (Month): 30%')
      expect(page).to have_content('Notes: Sparkling clean')

      within('table') do
        within('thead') do
          expect(page).to have_content('Number')
          expect(page).to have_content('Status')
          expect(page).to have_content('Period')
          expect(page).to have_content('Duration')
          expect(page).to have_content('Guest Name')
          expect(page).to have_content('# of guests')
          expect(page).to have_content('Actions')
        end

        within('tbody tr:first-child') do
          expect(page).to have_content('147-01')
          expect(page).to have_content('Planned')
          expect(page).to have_content("#{@room.reservations.first.start_date} to #{@room.reservations.first.end_date}")
          expect(page).to have_content('8 nights')
          expect(page).to have_content('João Santana')
          expect(page).to have_content('1 guest')
        end

        within('tbody tr:last-child') do
          expect(page).to have_content('147-02')
          expect(page).to have_content('Planned')
          expect(page).to have_content("#{@room.reservations.second.start_date} to #{@room.reservations.second.end_date}")
          expect(page).to have_content('1 night')
          expect(page).to have_content('Carolina dos Anjos')
          expect(page).to have_content('3 guests')
        end
      end
    end

    context 'when deleting a reservation for the room' do
      before do
        visit room_path(@room.id)

        expect(page).to have_selector('table tbody tr', count: 2)

        within('table tbody tr:first-child') do
          accept_alert do
            click_link 'Destroy'
          end
        end
      end

      it 'allows users to delete a reservation' do
        expect(page).to have_selector('table tbody tr', count: 1)
        expect(page).to have_content('Reservation 147-01 was successfully destroyed.')
      end

      context 'when guest email is informed' do
        it 'sends a cancellation mail to the guest' do
          expect(page).to have_content('was successfully destroyed.')
          expect(ActionMailer::Base.deliveries.count).to eq(1)
          expect(ActionMailer::Base.deliveries.first.to).to include('joaosantana@example.com')
        end
      end
    end

    it 'has a link to edit the room details' do
      visit room_path(@room.id)

      expect(page).to have_link('Edit', href: edit_room_path(@room.id))
    end

    it 'has a link to go back to the listing' do
      visit room_path(@room.id)

      expect(page).to have_link('Back', href: rooms_path)
    end

    context 'when the room has no reservations' do
      before do
        @room.reservations.destroy_all
      end

      it 'shows an empty listing' do
        visit room_path(@room.id)

        within('table') do
          expect(page).to have_content('There are no reservations for this room')
        end
      end
    end
  end

  describe 'edit room' do
    before do
      @room = create(:room, code: '147', capacity: '4')
    end

    it 'allows users to change attributes of a room' do
      visit edit_room_path(@room.id)

      fill_in 'Code', with: '190'
      click_on 'Update Room'

      expect(page).to have_current_path(room_path(@room.id))
      expect(page).to have_content('Room was successfully updated')
    end

    it 'shows an error message when there is a validation error' do
      visit edit_room_path(@room.id)

      fill_in 'Code', with: ''
      click_on 'Update Room'

      expect(page).to have_content("can't be blank")
    end

    it 'has a link to show the room details' do
      visit edit_room_path(@room.id)

      expect(page).to have_link('Show', href: room_path(@room.id))
    end

    it 'has a link to go back to the listing' do
      visit edit_room_path(@room.id)

      expect(page).to have_link('Back', href: rooms_path)
    end
  end
end
