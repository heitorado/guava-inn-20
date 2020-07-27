class RoomsController < ApplicationController
  before_action :set_room, only: [:show, :edit, :update, :destroy]

  def index
    @rooms = Room.all

    @month_global_occupancy_rate = @rooms.map(&:month_occupancy_rate).sum / (@rooms.count.nonzero? || 1)
    @week_global_occupancy_rate = @rooms.map(&:week_occupancy_rate).sum / (@rooms.count.nonzero? || 1)
    @month_total_reservations = Reservation.happening_between(Date.tomorrow, 30.days.from_now).count
    @week_total_reservations = Reservation.happening_between(Date.tomorrow, 7.days.from_now).count
  end

  def show
  end

  def new
    @room = Room.new
  end

  def edit
  end

  def create
    @room = Room.new(room_params)

    if @room.save
      redirect_to @room, notice: 'Room was successfully created.'
    else
      render :new
    end
  end

  def update
    if @room.update(room_params)
      redirect_to @room, notice: 'Room was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @room.destroy
    redirect_to rooms_url, notice: 'Room was successfully destroyed.'
  end

  def search_occupancy_rate
    @valid_search = params[:start_date].present? &&
                    params[:end_date].present? &&
                    params[:start_date].to_date <= params[:end_date].to_date

    @start_date = params[:start_date].to_date
    @end_date = params[:end_date].to_date

    if @valid_search
      @occupancy_rate = Room.all.map do |room|
        room.occupancy_rate_for_the_next((@end_date - @start_date).to_i + 1, @start_date)
      end

      @occupancy_rate = @occupancy_rate.sum / @occupancy_rate.count
      @total_reservations = Reservation.happening_between(@start_date, @end_date).count
    end

    respond_to do |format|
      format.js
    end
  end

  private

  def set_room
    @room = Room.find(params[:id])
  end

  def room_params
    params.require(:room).permit(:code, :capacity, :notes)
  end
end
