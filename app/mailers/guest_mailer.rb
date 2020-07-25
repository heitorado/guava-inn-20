class GuestMailer < ApplicationMailer
  def reservation_confirmed
    @reservation = params[:reservation]
    mail(to: @reservation.guest_email, subject: '[Guava Inn] Reserva confirmada!')
  end

  def reservation_cancelled
    @reservation = params[:reservation]
    mail(to: @reservation.guest_email, subject: '[Guava Inn] Reserva cancelada :(')
  end
end
