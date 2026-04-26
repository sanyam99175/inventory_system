class UpgradeController < ApplicationController
  def show
    @feature = params[:feature]
  end
end