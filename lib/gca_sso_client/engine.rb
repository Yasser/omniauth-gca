module GcaSsoClient
  class Engine < ::Rails::Engine
    require 'app/controllers/gca_sso_client/concerns/gca_sso_client_authentication'

    isolate_namespace GcaSsoClient
  end
end