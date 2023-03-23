class ActivitiesController < ApplicationController
  def index
    @trip = Trip.find(params[:trip_id])
    @eat = @trip.activities.where(category: :eat, status: :pending)
    @explore = @trip.activities.where(category: :explore, status: :pending)
    @do = @trip.activities.where(category: :do, status: :pending)
    @selected_activities = selected_activities

    @activities = @trip.activities.all
  end

  def selected_activities
    @trip = Trip.find(params[:trip_id])
    @selected_activities = @trip.activities.where(status: :added)
    @markers = Activity.generate_markers_json(@trip.activities.selected)
  end

  def added
    @trip = Trip.find(params[:trip_id])
    @activity = Activity.find(params[:id])
    @activity.added!
    redirect_to trip_activities_path(@trip)
  end

  def favourite
    @trip = Trip.find(params[:trip_id])
    @activity = Activity.find(params[:id])
    @activity.favourite!
    redirect_to trip_activities_path(@trip)
  end
end
