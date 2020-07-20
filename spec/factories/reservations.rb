FactoryBot.define do
  factory :reservation do
    transient do
      on_room { {} }
    end

    room
    start_date { rand(0..40).days.ago }
    end_date { rand(1..40).days.from_now }
    guest_name { 'Sybil Fawlty' }
    number_of_guests { room.nil? ? rand(1..10) : rand(1..room.capacity) }

    after(:build) do |reservation, evaluator|
      reservation.room = build(:room, evaluator.on_room) if evaluator.on_room.present?
    end
  end
end
