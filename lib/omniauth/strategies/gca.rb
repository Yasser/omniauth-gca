require 'omniauth-oauth2'
require 'faraday'

module OmniAuth
  module Strategies
    class Gca < OmniAuth::Strategies::OAuth2
      class << self
        attr_accessor :gca_sso_token
      end

      if Rails.env.production?
        if ENV["STAGING"] == "true"
          option :client_options, {
            :site =>  "http://gca-sso-staging.herokuapp.com",
            :authorize_url => "http://gca-sso-staging.herokuapp.com/oauth/authorize",
            :access_token_url => "http://gca-sso-staging.herokuapp.com/oauth/token"
          }
        else
          option :client_options, {
            :site =>  "https://sso.usap-colorado.com",
            :authorize_url => "https://sso.usap-colorado.com/oauth/authorize",
            :access_token_url => "https://sso.usap-colorado.com/oauth/token"
          }
        end
      else
        option :client_options, {
          :site =>  "http://0.0.0.0:3000",
          :authorize_url => "http://0.0.0.0:3000/oauth/authorize",
          :access_token_url => "http://0.0.0.0:3000/oauth/token"
        }
      end

      uid { raw_info['user']['uid'] }

      info do
        {
          email: raw_info['user']['email'],
          first_name: raw_info['user']['first_name'],
          last_name: raw_info['user']['last_name'],
          legal_first_name: raw_info['user']['legal_first_name'],
          legal_last_name: raw_info['user']['legal_last_name'],
          title: raw_info['user']['title'],
          npi: raw_info['user']['npi'],
          group: raw_info['user']['user_groups']
        }
      end

      extra do
        {
          session_trusted: raw_info['session']['trusted'],
          expires_at: raw_info['session']['expires_at']
        }
      end

      def raw_info
        @raw_info ||= access_token.get("/api/user.json").parsed
      end
    end
  end
end

class GcaSsoApi
  def initialize(request_uri, params={}, user_token=nil)
    @request_uri = request_uri
    @params = params
    @provider_host = OmniAuth::Strategies::Gca.default_options['client_options']['site']
    @user_token = user_token
    if @user_token
      @client = Faraday.new(@provider_host)
    else
      @client = OAuth2::Client.new(ENV["GCA_SSO_APP_ID"], ENV["GCA_SSO_APP_SECRET"], site: @provider_host, :raise_errors => false)
      @token = @client.client_credentials.get_token
    end
    @response = nil
  end
  
  def get
    if @user_token
      @response = @client.get do |req|
        req.url @request_uri
        req.headers['Authorization'] = "Bearer #{@user_token}"
        req.params = @params
      end
    else
      @response = token.get(@request_uri, params: @params)
    end
  end
  
  def post
    if @user_token
      @response = @client.post do |req|
        req.url @request_uri
        req.headers['Authorization'] = "Bearer #{@user_token}"
        req.body = @params
      end
    else
      @response = token.post(@request_uri, params: @params)
    end
  end
  
  def response
    @response
  end
  
  def token
    @token
  end
end