class PwaController < ApplicationController
  def manifest
    render "pwa/manifest", formats: [:json]
  end
end