namespace :sync do
  
  desc "Syncs all users and access groups with GCA SSO"
  task all: :environment do
    Rake::Task["gcassoclient:sync:access_groups"].invoke
    Rake::Task["gcassoclient:sync:users"].invoke
  end
  
  desc "Syncs users (GcaSsoClient::User) with GCA SSO"
  task users: :environment do
    puts "Syncing users...\n"
    
    request = GcaSsoApi.new("/api/users")
    response = request.get

    if response.status == 200
      users = response.parsed
      users.each do |user|
        u = User.where(uid: user["uid"])
        if u.exists?
          u = u.first
          attributes = {}
          attributes.merge!(access_group_ids: AccessGroup.where(key: user["user_groups"]).pluck(:id))
          [:first_name, :last_name, :title, :npi].each do |attribute|
            attributes.merge!(attribute => user[attribute.to_s]) if u.send(attribute) != user[attribute.to_s]
          end
          u.assign_attributes(attributes)
        else
          u = User.new(uid: user["uid"], access_group_ids: AccessGroup.where(key: user["user_groups"]).pluck(:id), email: user["email"], first_name: user['first_name'], last_name: user['last_name'], title: user['title'], npi: user['npi'])
        end
        u.save if u.changed?
      end
      Rails.cache.write(:user_list_updated_at, Time.now)

      puts "done.\n"
    else
      puts "The API server responded with an error. No users were synced.\n"
    end
  end
  
  desc "Syncs access groups (GcaSsoClient::AccessGroup) with GCA SSO"
  task access_groups: :environment do
    puts "Syncing access groups...\n"
    request = GcaSsoApi.new("/api/users/groups")
    response = request.get
  
    if response.status == 200
      access_groups = JSON.parse request.response.body
      
      puts "#{access_groups['groups'].size} groups found.\n"
      
      access_groups["groups"].each do |group|
        if !AccessGroup.where(key: group["key"]).exists?
          puts "Creating access group: #{group['key']}\n"
          
          AccessGroup.create(key: group["key"], title: group["title"], group_key: group["group"], group_title: access_groups["categories"].select{|c| c["key"] == group["group"]}.first["title"])
        end
      end
    else
      puts "The API server responded with an error. No access groups were synced.\n"
    end
    
    puts "done.\n"
  end
  
end