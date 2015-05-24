require 'rails/generators/active_record'

# rails g gca_sso_client:migration 
class GcaSsoClient::MigrationGenerator < ::Rails::Generators::Base
  include Rails::Generators::Migration
  source_root File.expand_path('../templates', __FILE__)
  desc 'Installs GcaSsoClient migration file.'

  def install
    migration_template 'migration.rb', 'db/migrate/create_gca_sso_client_tables.rb'
  end

  def self.next_migration_number(dirname)
    ActiveRecord::Generators::Base.next_migration_number(dirname)
  end
end