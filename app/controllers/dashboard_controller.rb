class DashboardController < ApplicationController

  def show
  end

  def landing
    redirect_to action: :show
  end
end
