class AddGuestEmailToReservation < ActiveRecord::Migration[6.0]
  def change
    add_column :reservations, :guest_email, :string, default: ''
  end
end
