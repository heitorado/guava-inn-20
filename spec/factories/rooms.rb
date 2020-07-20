FactoryBot.define do
  factory :room do
    transient do
      # If set as true, creates a random reservation
      with_random_reservation { false }
      # If the array is filled with each element being a hash with reservation attributes
      # (all or partial) then they will be used to create the reservations to the room.
      with_reservations { [] }
    end

    sequence(:code, '101')
    capacity { rand(1..10) }
    notes { 'Lorem Ipsum Dolor Sit Amet' }

    after(:create) do |room, evaluator|
      if evaluator.with_random_reservation
        create(:reservation, room: room)
      elsif evaluator.with_reservations.present?
        evaluator.with_reservations.each do |attrs|
          attrs.merge!(room: room)
          create(:reservation, attrs)
        end
      end
    end
  end
end
