class UsersController < ApplicationController
  def index
    @trips = Trip.where(user_id: current_user.id)
  end

  def show
    @user = current_user
    upcoming_trips = Trip.where(user_id: current_user.id).where("start_date > ?", Date.today)

    if upcoming_trips.present?
      @next_trip = upcoming_trips.sort.first
      @past_trips = Trip.where(user_id: current_user.id).where("end_date < ?", Date.today)
      @last_trip = @past_trips.sort.first

      @markers = @past_trips.geocoded.map do |trip|
        {
          lat: trip.latitude,
          lng: trip.longitude,
          info_window_html: render_to_string(partial: "/trips/info_window", locals: { trip:}),
          marker_html: render_to_string(partial: "/trips/marker", locals: { trip: })
        }
      end
    end
  end
end
