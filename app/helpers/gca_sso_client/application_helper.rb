module GcaSsoClient
  module ApplicationHelper
    
    module GcaSsoClientHelperMethods
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

      def user_signed_in?
        return true if current_user
      end
  
      def message_user_link(user, name_method="")
        opts = {}
        opts.merge!(class: "self") if current_user == user
        name_method = name_method.to_s.match(/name|first_name|last_name|name_last_first|short_name/) ? name_method.to_sym : :name
        host = OmniAuth::Strategies::Gca.default_options['client_options']['site']
        link_to user.send(name_method), "#{host}/users/#{user.uid}/messages/new", opts
      end
    end
    include GcaSsoClientHelperMethods
    
  end
end