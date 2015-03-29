module GcaSsoClient
  class ApplicationController < Rails::Application::ApplicationController

    unless method_defined? :expire_session
      def expire_session
        redirect_to signout_url, _method: :delete, notice: "Your session has ended due to inactivity. Please <a href=\"#{signin_url}\">sign in</a> again.".html_safe
      end
    end
  
  end
end