module GcaSsoClient
  class AccessGroup < ActiveRecord::Base
    self.table_name = "access_groups"
    
    has_and_belongs_to_many :users
  end
end
