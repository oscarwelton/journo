class TripsController < ApplicationController
  @@client = OpenAI::Client.new

  def index
    @user = current_user

    if params[:query].present?
      sql_query = "trip_name ILIKE :query OR destination ILIKE :query"
      @trips = Trip.where(sql_query, query: "%#{params[:query]}%")
    else
      @trips = Trip.where(user_id: current_user.id)
    end
  end

  def new
    @trip = Trip.new
  end

  def show
    @note = Note.new
    @trip = Trip.find(params[:id])
    @activities = @trip.activities.where(status: :added)

    restaurants = @activities.where(category: :eat).pluck(:name)
    dos = @activities.where(category: :do).pluck(:name)
    exps = @activities.where(category: :explore).pluck(:name)

    activity_names = (dos + exps).uniq

    itinerary_prompt = "I am going on a trip to #{@trip.destination}.
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
    @infos = itinerary_response.parsed_response['choices'][0]['text']

    # accomodation_prompt = "Suggest me 5 areas to stay in #{@trip.destination}.
    # These should suit a range of budgets. Each area should have a one line description.
    # It should be a HTML list format."

    # budget_response = @@client.completions(
    #   parameters: {
    #     model: "text-davinci-003",
    #     prompt: accomodation_prompt,
    #     max_tokens: 2000,
    #     temperature: 0.1
    #   }
    # )
    # @accom = budget_response.parsed_response['choices'][0]['text']
  end

  def create
    @trip = Trip.new(trip_params)
    @trip.user = current_user
    if @trip.save
      redirect_to trip_activities_path(@trip)
    else
      render :new
    end
  end

  private

  def trip_params
    params.require(:trip).permit(:start_date, :end_date, :trip_name, :destination)
  end
end
