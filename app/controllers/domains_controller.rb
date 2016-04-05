class DomainsController < ApplicationController

  def index
    authorize :domain, :index?
    @domains = Domain.all
  end

end
