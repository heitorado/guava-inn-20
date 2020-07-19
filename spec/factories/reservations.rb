FactoryBot.define do
  factory :reservation do
    room { create(:room) }
    start_date { rand(0..40).days.ago }
    end_date { rand(0..40).days.from_now }
    guest_name { 'Sybil Fawlty' }
    number_of_guests { rand(1..room.capacity) }
  end
end
