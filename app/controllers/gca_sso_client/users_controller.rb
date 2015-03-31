module GcaSsoClient
  class UsersController < ApplicationController
    before_action :authenticate_user!
    before_action :current_user_acts_as_admin, only: [:index, :destroy]  
    
    def index
      @users = User.all
    end
    
    def destroy
      @user = User.find(params[:id])
      @user.destroy
    
      respond_to do |format|
        format.html { redirect_to users_url, :notice => "User has been deleted" }
        format.json { head :ok }
      end
    end
  
    def sync
      request = GcaSsoApi.new("/api/users/groups")
      response = request.get
    
      if response.status == 200
        access_groups = JSON.parse request.response.body
        access_groups["groups"].each do |group|
          AccessGroup.create(key: group["key"], title: group["title"], group_key: group["group"], group_title: access_groups["categories"].select{|c| c["key"] == group["group"]}.first["title"]) if !AccessGroup.where(key: group["key"]).exists?
        end
      end

      last_modified = Rails.cache.read(:user_list_updated_at) || User.order("created_at ASC").last.created_at
      if Time.now - last_modified > 15.minutes || params[:force] == "force"
        request = GcaSsoApi.new("/api/users/since/#{last_modified.strftime('%Y-%m-%d-%H:%M')}")
        response = request.get
    
        if response.status == 200
          users = response.parsed
          users.each do |user|
            u = User.where(uid: user["uid"])
            if u.exists?
              u = u.first
              attributes = {}
              attributes.merge!(access_group_ids: AccessGroup.where(key: user["user_groups"]).pluck(:id))
              [:first_name, :last_name, :title].each do |attribute|
                attributes.merge!(attribute => user[attribute.to_s]) if u.send(attribute) != user[attribute.to_s]
              end
              u.assign_attributes(attributes)
            else
              u = User.new(uid: user["uid"], access_group_ids: AccessGroup.where(key: user["user_groups"]).pluck(:id), email: user["email"], first_name: user['first_name'], last_name: user['last_name'], title: user['title'])
            end
            u.save if u.changed?
          end
          Rails.cache.write(:user_list_updated_at, Time.now)
        end
      end
    
      redirect_to users_url
    end
    
  end
end