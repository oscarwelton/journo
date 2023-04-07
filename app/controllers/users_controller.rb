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

    return unless current_user.activities.nil?

    activity_prompt = "I am going on a trip to #{@trip.destination}.
      The itinerary must be for #{(@trip.end_date - @trip.start_date).to_i} days.
      I want to visit: #{activity_names}.
      I want to eat at: #{restaurants}.
      Each day should suggest at least one restaurant and one activity.
      Do not repeat an item.
      The itinerary clearly shows restaurants and activities.
      The itinerary does not have to include everything.
      Please format the response in a HTML list."

    itinerary_response = @@client.completions(
      parameters: {
        model: "text-davinci-003",
        prompt: itinerary_prompt,
        max_tokens: 2000,
        temperature: 0.1
      }
    )
    itinerary = itinerary_response.parsed_response['choices'][0]['text']
    @trip.update(itinerary:)
  end
end
