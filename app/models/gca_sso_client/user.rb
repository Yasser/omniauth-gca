module GcaSsoClient
  class User < ActiveRecord::Base
    self.primary_key = :uid
    self.table_name = "users"

    has_and_belongs_to_many :access_groups
    
    validates :email, :presence => true, :uniqueness => true
  
    default_scope { order('LOWER(last_name)') } 
  
    def acts_as(*role_array)
      return true if admin?
      # Array as OR not AND -- just looks for one match
      role_array = [role_array].flatten.map &:to_sym
      !(roles & role_array).empty?
    end
  
    def last_activity
      if current_sign_in_at.nil?
        last_sign_in_at.nil? ? "Never" : last_sign_in_at.strftime("%b %e, %Y at %H:%M")
      else
        current_sign_in_at.strftime("%b %e, %Y at %H:%M")
      end
    end
  
    def name
      self.title.blank? ? "#{first_name} #{last_name}" : "#{first_name} #{last_name}, #{title}"
    end
  
    def name_last_first
      "#{last_name}, #{first_name}"
    end
  
    def short_name
      "#{first_name[0]}. #{last_name}"
    end

    def roles
      access_groups.pluck(:key).map{|g| g.to_sym}
    end
  
    def rotate_timestamps(commit_changes=true)
      assign_attributes(current_sign_in_at: nil, current_sign_in_ip: nil, last_sign_in_at: current_sign_in_at, last_sign_in_ip: current_sign_in_ip)
      save if commit_changes
    end
  
    def set_timestamps_from_request(request)
      # Rotate timestamps if session expired instead of being destroyed
      rotate_timestamps(false) if !current_sign_in_at.nil?
      assign_attributes(current_sign_in_at: Time.now, current_sign_in_ip: request.remote_ip)
    end
  
    def to_s
      short_name
    end
  end
end