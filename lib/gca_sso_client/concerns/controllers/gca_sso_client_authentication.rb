module GcaSsoClient::Concerns::Controllers::Authentication
  extend ActiveSupport::Concern
  
  protected

  def authenticate_user!
    redirect_to signin_url unless user_signed_in?
  end

  def current_user
    return nil if session[:user].nil?
    @current_user ||= User.find_by(uid: session[:user])
  end

  def expire_session
    redirect_to signout_url, _method: :delete, notice: "Your session has ended due to inactivity."
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
    redirect_to (request.referer || root_url), :alert => message
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