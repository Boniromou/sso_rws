class DashboardController < ApplicationController
  layout proc {|controller| controller.request.xhr? ? false: "dashboard" }
end
