module GcaSsoClient
  class Engine < ::Rails::Engine
    def self.root
      File.expand_path(File.dirname(File.dirname(__FILE__)))
    end

    def self.models_dir
      path_for(:models)
    end

    def self.controllers_dir
      path_for(:controllers)
    end
    
    def self.views_dir
      path_for(:views)
    end
    
    def self.path_for(e)
      File.join("#{root}", "../app/#{e}/gca_sso_client")
    end
    
    isolate_namespace GcaSsoClient
  end
end