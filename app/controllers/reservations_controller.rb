class ReservationsController < ApplicationController
  def search
    @should_show_results = params[:number_of_guests].present? &&
                           start_and_end_date_present?

    if start_and_end_date_present? && !start_date_is_before_end_date?
      @should_show_results = false
      flash[:alert] = "Cannot search: the 'From' date must happen before the 'To' date"
    end

    @available_rooms = if @should_show_results
                         Room.minimum_capacity_of(params[:number_of_guests]) -
                           Room.unavailable_for_period(params[:start_date], params[:end_date])
                       else
                         Room.none
                       end
  end

  def new
    @reservation = Reservation.new(reservation_params)
    @room = params.dig(:reservation, :room_id)
  end

  def create
    @reservation = Reservation.new(reservation_params)
    if @reservation.save
      redirect_to @reservation.room,
                  notice: "Reservation #{@reservation.code} was successfully created."
    else
      render :new
    end
  end

  def destroy
    @reservation = Reservation.find(params[:id])
    @reservation.destroy
    redirect_to room_path(@reservation.room),
                notice: "Reservation #{@reservation.code} was successfully destroyed."
  end

  private

  def start_and_end_date_present?
    params[:start_date].present? && params[:end_date].present?
  end

  def start_date_is_before_end_date?
    return false unless start_and_end_date_present?

    params[:start_date].to_date.before?(params[:end_date].to_date)
  end

  def reservation_params
    params.require(:reservation).permit(:start_date, :end_date, :number_of_guests, :guest_name, :room_id)
  end
end
