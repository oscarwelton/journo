class Trip < ApplicationRecord
  belongs_to :user
  has_one :note, dependent: :destroy
  has_many :activities, dependent: :destroy

  validates :trip_name, :destination, presence: true

  after_commit :generate_activities, on: :create
  after_commit :generate_budget, on: :create
  after_commit :generate_packing_list, on: :create
  after_commit :generate_visa, on: :create

  geocoded_by :destination

  after_validation :geocode

  @@client = OpenAI::Client.new

  def call_gpt(prompt, category)
    response = @@client.completions(
      parameters: {
        model: "text-davinci-003",
        prompt:,
        max_tokens: 2000,
        temperature: 0.3
      }
    )

    infos = response.parsed_response['choices'][0]['text']
    activities = JSON.parse(infos)

    activities.each do |info|
      Activity.create(name: info['name'], description: info['description'], latitude: info['lat'], longitude: info['lon'], category:,
                      trip: self)
    end
  end

  def generate_activities
    destination = self.destination
    eat_preference = user.eat_preference_list
    do_preference = user.do_preference_list

    explore_prompt = "You are a travel consultant. recommend the 5 best activities in #{destination}.
    Response must be a JSON with inside an array of activities with only the keys called name, description rating and lat and lon."

    eat_prompt = "You are a travel consultant. recommend the 5 best restaurants in #{destination} that are: #{eat_preference}.
    Response must be a JSON with inside an array of activities with only the keys called name, description and lat and lon."

    do_prompt = "You are a travel consultant. 5 best activities in #{destination} that involve: #{do_preference}.
    Response must be a JSON with inside an array of activities with only the keys called name, description and lat and lon."

    GenerateActivitiesJob.perform_later(self, eat_prompt, 0)
    GenerateActivitiesJob.perform_later(self, do_prompt, 1)
    GenerateActivitiesJob.perform_later(self, explore_prompt, 2)
  end

  def generate_budget
    GenerateBudgetJob.perform_later(self)
  end

  def generate_packing_list
    GeneratePackingListJob.perform_later(self)
  end

  def generate_visa
    GenerateVisaJob.perform_later(self)
  end

  require 'icalendar'

  def to_icalendar
    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart     = start_date
      e.dtend       = end_date
      e.summary     = trip_name
      e.description = Nokogiri::HTML(itinerary).text
      e.location    = destination
      e.ip_class    = "PUBLIC"
    end
    cal.publish
    cal.to_ical
  end
end
