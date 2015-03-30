module GcaSsoClient
  class ApplicationController < ActionController::Base
    include GcaSsoClient::Authentication
  end
end