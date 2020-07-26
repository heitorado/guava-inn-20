class ReservationsController < ApplicationController
  after_action :save_last_search_url, only: [:search]

  def search
    @should_show_results = params[:number_of_guests].present? &&
                           start_and_end_date_present?

    if start_and_end_date_present? && !start_date_is_before_end_date?
      @should_show_results = false
      flash[:alert] = "Cannot search: the 'From' date must happen before the 'To' date"
    end

    unless start_and_end_date_present? || params[:commit].blank?
      flash[:alert] = 'Cannot search: you must fill both date fields.'
    end

    @available_rooms = if @should_show_results
                         Room.minimum_capacity_of(params[:number_of_guests]) -
                           Room.unavailable_for_period(params[:start_date], params[:end_date])
                       else
                         Room.none
                       end
  end

  def new
    @back_url = session[:last_search_url]
    @reservation = Reservation.new(reservation_params)
  end

  def create
    @back_url = session[:last_search_url]
    @reservation = Reservation.new(reservation_params)
    if @reservation.save
      GuestMailer.with(reservation: @reservation).reservation_confirmed.deliver if @reservation.guest_email.present?

      redirect_to @reservation.room,
                  notice: "Reservation #{@reservation.code} was successfully created."
    else
      render :new
    end
  end

  def destroy
    @reservation = Reservation.find(params[:id])
    @reservation.destroy

    GuestMailer.with(reservation: @reservation).reservation_cancelled.deliver if @reservation.guest_email.present?

    redirect_to @reservation.room,
                notice: "Reservation #{@reservation.code} was successfully destroyed."
  end

  private

  def save_last_search_url
    session[:last_search_url] = request.fullpath || search_reservations_path
  end

  def start_and_end_date_present?
    params[:start_date].present? && params[:end_date].present?
  end

  def start_date_is_before_end_date?
    return false unless start_and_end_date_present?

    params[:start_date].to_date.before?(params[:end_date].to_date)
  end

  def reservation_params
    params.require(:reservation).permit(:start_date, :end_date, :number_of_guests, :guest_name, :guest_email, :room_id)
  end
end
