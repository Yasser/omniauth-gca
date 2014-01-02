require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Gca < OmniAuth::Strategies::OAuth2
      GCA_SSO_PROVIDER_URL = ENV["GCA_SSO_GATEWAY"]
      
      class << self
        attr_accessor :gca_sso_token
      end

      option :client_options, {
        :site =>  GCA_SSO_PROVIDER_URL,
        :authorize_url => "#{GCA_SSO_PROVIDER_URL}/oauth/authorize",
        :access_token_url => "#{GCA_SSO_PROVIDER_URL}/oauth/token"
      }

      uid { raw_info['id'] }

      info do
        {
          :name => "#{raw_info['info']['first_name']} #{raw_info['info']['last_name']}",
          :email => raw_info['info']['email'],
          :first_name => raw_info['info']['first_name'],
          :last_name  => raw_info['info']['last_name']
        }
      end

      extra do
        {
        }
      end

      def raw_info
        @raw_info ||= access_token.get("/api/user.json").parsed
      end
    end
  end
end

# Handles storing the token in session and passing it on to ActiveResource
# model via the @headers instance variable. In order to set, this requires 
# 'class_attribute :headers' to be set in the model.

class GcaSsoToken
  def initialize(session, *classes_to_set_token_on)
    @session = session
    @classes = classes_to_set_token_on
  end
  
  def token=(token)
    @session[:gca_sso_token] = token
    @classes.each do |c|
      c.headers = token.nil? ? {} : { 'AUTHORIZATION' => 'Token token="' << token << '", gca_sso=true'}
    end
  end
  
  def token
    @session[:gca_sso_token]
  end
end