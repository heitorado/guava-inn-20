module RoomsHelper
  def get_status_of(reservation)
    return 'Finished' if reservation.end_date <= Date.current
    return 'Ongoing'  if reservation.start_date <= Date.current && reservation.end_date >= Date.current
    return 'Planned'  if reservation.start_date > Date.current
  end
end
