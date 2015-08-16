require_dependency "gca_sso_client/application_controller"

module GcaSsoClient
  class SessionsController < ApplicationController
    before_action :sync_access_groups, only: [:create]
    skip_before_action :authenticate_user!
    skip_before_action :validate_session
  
    def index
      redirect_to :signin unless Rails.configuration.sso_redirect_as_session_index == false
    end
  
    def new
      redirect_to '/auth/gca'
    end

    def create
      auth = request.env["omniauth.auth"]
      roles = auth['info']['group']
    
      redirect_to after_session_destroy_path(:unauthorized), alert: "You do not have sufficient priveleges to use this application." unless permitted(roles)

      user = User.find_by(uid: auth['uid'])
    
      if user
        attributes = {access_group_ids: AccessGroup.where(key: roles).pluck(:id), admin: roles.include?("admin")}
        [:first_name, :last_name, :legal_first_name, :legal_last_name, :title, :npi].each do |n|
          attributes.merge!({n => auth['info'][n.to_s]}) if user.respond_to?(n) && auth['info'][n.to_s] != user.send(n)
        end
        user.assign_attributes(attributes)
        user.set_timestamps_from_request(request)
        user.save
      else
        params_from_sso = {uid: auth['uid'], first_name: auth['info']['first_name'], last_name: auth['info']['last_name'], title: auth['info']['title'], npi: auth['info']['npi'], email: auth['info']['email'], access_group_ids: AccessGroup.where(key: roles).select(:id).map(&:id), admin: roles.include?("admin"), current_sign_in_at: Time.now, current_sign_in_ip: request.remote_ip}
        parameters = ActionController::Parameters.new(params_from_sso)
        user_attribute_names = (defined?(::User) ? ::User : User).attribute_names.map(&:to_sym)
        existing_attributes = user_attribute_names & [:uid, :first_name, :last_name, :legal_first_name, :legal_last_name, :title, :email, :npi, :admin, :current_sign_in_at, :current_sign_in_ip]
        user = User.create(parameters.permit(*existing_attributes, :access_group_ids => []))
      end
      session[:user] = user.uid
      session[:user_token] = auth['credentials']['token']
      session[:trusted] = auth['extra']['session_trusted']
      session[:expires_at] = Time.parse(auth['extra']['expires_at']) if session[:trusted]
      session[:last_activity] = Time.now
    
      flash[:notice] = "Successfully signed in. Welcome, #{user.name}."
    
      redirect_to after_session_create_path
    end

    def destroy
      if session[:user]
        prior_flash = flash[:notice] || "You have successfully signed out."
        User.find_by(uid: session[:user]).rotate_timestamps
        reset_session
      end
      flash[:notice] = prior_flash unless Rails.configuration.sso_redirect_after_session_destroy
      redirect_to after_session_destroy_path(:signedout)
    end

    def failure
      redirect_to after_session_destroy_path("Authentication error: #{params[:message].humanize}"), alert: "Authentication error: #{params[:message].humanize}"
    end
  
    def idle
      expire_session
    end

    protected
    
    def permitted(roles)
      (roles & [permitted_roles].flatten).size > 0 || roles.include?("admin") || permitted_roles == :all
    end
  
    def permitted_roles
      Rails.configuration.respond_to?(:sso_permitted_roles) ? Rails.configuration.sso_permitted_roles : :all
    end
  
    def sso_url
      OmniAuth::Strategies::Gca.default_options['client_options']['site']
    end
  
    def sync_access_groups
      access_groups = Rails.cache.fetch(:access_groups, expires_in: 1.day) do
        request = GcaSsoApi.new('/api/users/groups.json').get
        if request.response.status == 200
          access_groups = JSON.parse request.response.body
        end
        access_groups
      end
      access_groups["groups"].each do |group|
        AccessGroup.create(key: group["key"], title: group["title"], group_key: group["group"], group_title: access_groups["categories"].select{|c| c["key"] == group["group"]}.first["title"]) if !AccessGroup.where(key: group["key"]).exists?
      end
    end
  
  end
end