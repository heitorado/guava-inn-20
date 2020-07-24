module RoomsHelper
  def get_status_of(reservation)
    return 'Finished' if reservation.end_date <= Date.today
    return 'Ongoing'  if reservation.start_date <= Date.today && reservation.end_date >= Date.today
    return 'Planned'  if reservation.start_date > Date.today
  end
end
