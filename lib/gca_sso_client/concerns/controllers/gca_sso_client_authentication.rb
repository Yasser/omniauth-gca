module GcaSsoClient
  module Authentication
    
    extend ActiveSupport::Concern

    protected

    def after_session_create_path
      request.env['omniauth.origin'].include?(main_app.root_url) ? request.env['omniauth.origin'] : main_app.root_url
    rescue
      main_app.root_url
    end
    
    def after_session_destroy_redirect_path(message=nil)
      catch_message = message.nil? ? "" : "/#{message}"
      "#{sso_url}/sessions/catch/#{ENV["GCA_SSO_APP_ID"]}#{catch_message}"
    end
  
    def after_session_destroy_path(message=nil)
      Rails.configuration.sso_redirect_after_session_destroy ? after_session_destroy_redirect_path(message) : main_app.root_url
    end

    def authenticate_user!
      redirect_to gca_sso_client.signin_url unless user_signed_in?
    end

    def current_user
      return nil if session[:user].nil?
      
      main_app_user_class = ::User
      engine_user_class = User
      user_class = defined?(main_app_user_class) ? main_app_user_class : engine_user_class
      if @current_user && @current_user.is_a?(user_class)
        @current_user
      else
        @current_user = user_class.find_by(uid: session[:user])
      end
    end

    def expire_session
      if (Rails.configuration.respond_to?(:sso_redirect_as_session_index) && Rails.configuration.sso_redirect_as_session_index == false) && (Rails.configuration.respond_to?(:sso_redirect_after_session_destroy) && Rails.configuration.sso_redirect_after_session_destroy != true)
        redirect_to gca_sso_client.signout_url, _method: :delete, notice: "Your session has ended due to inactivity."
      else
        # No flash message, since redirecting to SSO for re-authentication
        User.find_by(uid: session[:user]).rotate_timestamps
        reset_session
        redirect_to after_session_destroy_path(:timedout)
      end
    end

    def method_missing(m, *args)
      if match = /^current_user_acts_as_(\w+)/.match(m.to_s)
        if current_user
          only_allow_if(current_user.acts_as(match[1].split("_")))
        else
          only_allow_if(false)
        end
      else
        super
      end
    end

    def only_allow_if(condition, message=nil)
      message ||= 'You are not authorized to peform that action.'
      raise if !condition
    rescue
      redirect_to (request.referer || main_app.root_url), :alert => message
    end

    def user_signed_in?
      return true if current_user
    end

    def validate_session
      if user_signed_in?
        if session[:last_activity]
          expire_after = session[:trusted] ? 60.minutes : 15.minutes
          if Time.parse(session[:last_activity].to_s) + expire_after < Time.now
            expire_session
          else
            session[:last_activity] = Time.now
          end
        else
          expire_session
        end
      end
    end
    
  end
end