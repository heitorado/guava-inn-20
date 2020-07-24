require 'rails_helper'

RSpec.describe RoomsHelper, type: :helper do
  describe '#get_status_of' do
    it "returns 'Finished' for past reservations" do
      reservation = build(:reservation, start_date: 9.days.ago, end_date: Date.today)

      expect(helper.get_status_of(reservation)).to eq('Finished')
    end

    it "returns 'Ongoing' for current reservations" do
      reservation = build(:reservation, start_date: Date.today, end_date: 9.days.from_now)

      expect(helper.get_status_of(reservation)).to eq('Ongoing')
    end

    it "returns 'Planned' for future reservations" do
      reservation = build(:reservation, start_date: Date.tomorrow, end_date: 9.days.from_now)

      expect(helper.get_status_of(reservation)).to eq('Planned')
    end
  end
end
