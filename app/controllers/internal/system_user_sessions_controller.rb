class Internal::SystemUserSessionsController < ApplicationController
  skip_before_filter :authenticate_system_user!

  def create
p params
  end
end
