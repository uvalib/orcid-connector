class DashboardController < ApplicationController

  before_action :check_netbadge

  def show
  end

  def landing
    redirect_to action: :show
  end
end
