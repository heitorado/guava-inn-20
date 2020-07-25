require 'rails_helper'

RSpec.describe GuestMailer, type: :mailer do
  describe 'notify a confirmed reservation' do
    before do
      @reservation = create(:reservation)
      @mail = GuestMailer.with(reservation: @reservation).reservation_confirmed
    end

    it 'sends the email' do
      @mail.deliver

      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it 'renders the subject' do
      expect(@mail.subject).to eq('[Guava Inn] Reserva confirmada!')
    end

    it 'renders the receiver email' do
      expect(@mail.to).to eq([@reservation.guest_email])
    end

    it 'renders the sender email' do
      expect(@mail.from).to eq(['reservations@guava-inn.tech'])
    end

    it 'contains the guest name' do
      expect(@mail.body.encoded).to match(@reservation.guest_name.split.first)
    end

    it 'contains the reservation code' do
      expect(@mail.body.encoded).to match("Your reservation code is #{@reservation.code}")
    end

    it 'contains the reservation duration' do
      expect(@mail.body.encoded).to match("#{@reservation.duration} nights")
    end

    it 'contains the room code' do
      expect(@mail.body.encoded).to match("Room #{@reservation.room.code}")
    end
    it 'contains the reservation start date' do
      expect(@mail.body.encoded).to match(@reservation.start_date.to_s)
    end

    it 'contains the reservation end date' do
      expect(@mail.body.encoded).to match(@reservation.end_date.to_s)
    end
  end

  describe 'notify a cancelled reservation' do
    before do
      @reservation = create(:reservation)
      @mail = GuestMailer.with(reservation: @reservation).reservation_cancelled
    end

    it 'sends the email' do
      @mail.deliver

      expect(ActionMailer::Base.deliveries).to_not be_empty
    end

    it 'renders the subject' do
      expect(@mail.subject).to eq('[Guava Inn] Reserva cancelada :(')
    end

    it 'renders the receiver email' do
      expect(@mail.to).to eq([@reservation.guest_email])
    end

    it 'renders the sender email' do
      expect(@mail.from).to eq(['reservations@guava-inn.tech'])
    end

    it 'contains the guest name' do
      expect(@mail.body.encoded).to match(@reservation.guest_name.split.first)
    end

    it 'contains the reservation duration' do
      expect(@mail.body.encoded).to match("#{@reservation.duration} nights")
    end

    it 'contains the room code' do
      expect(@mail.body.encoded).to match("Room #{@reservation.room.code}")
    end
    it 'contains the reservation start date' do
      expect(@mail.body.encoded).to match(@reservation.start_date.to_s)
    end
    it 'contains the reservation end date' do
      expect(@mail.body.encoded).to match(@reservation.end_date.to_s)
    end
  end
end
