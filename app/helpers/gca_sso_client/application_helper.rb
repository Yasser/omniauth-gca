module GcaSsoClient
  module ApplicationHelper
    
    module GcaSsoClientHelperMethods
      def current_user
        return nil if session[:user].nil?
        @current_user ||= (defined?(::User) ? ::User : User).find_by(uid: session[:user])
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