class DashboardController < ApplicationController

  def show
    @user = User.find(@user_id)
  end

  def landing
    redirect_to action: :show
  end
end
