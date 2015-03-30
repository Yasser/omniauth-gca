module GcaSsoClient
  class ApplicationController < ActionController::Base
    include GcaSsoClient::Concerns::Controllers::Authentication
  end
end