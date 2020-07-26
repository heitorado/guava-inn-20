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

  private

  def set_room
    @room = Room.find(params[:id])
  end

  def room_params
    params.require(:room).permit(:code, :capacity, :notes)
  end
end
