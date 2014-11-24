class CollaborationsController < ApplicationController
  
  def index
    @collaborations = {}
    @current_user.projects.each do |project|
      project.collaborations.each do |collab|
        if collab.status == "pending"
          @collaborations[collab.id] = {
            user: User.find(collab.user_id).name,
            project: project.title,
            status: collab.status}
          end
      end
    end
  end


  def create
    new_collab = Collaboration.create(collaboration_params)
    notif_params = notification_params
    project = Project.find(params[:collaboration][:project_id])
    creator_id = User.find(project.user_id).id
    if @current_user.id != creator_id
      # Someone requests to colaborate on a project
      notif_params[:user_id] = creator_id
      new_collab.notifications.create(notif_params)
      redirect_to project_path(params[:collaboration][:project_id])
    else
      # Creator invites someone to collaborate on a project
      notif_params[:project_id] = project.id
      notif_params[:description] = "#{@current_user.name} has invited you to colaborate on #{project.title}!"
      new_collab.notifications.create(notif_params)
      redirect_to user_path(params[:notification][:user_id])
    end
  end

  def update
    collab = Collaboration.find(params[:id])
    collab.update(status: "collaborator")
    alter_notif = Notification.find(collab.notifications[0].id)
    notif_params = notification_params
    accepted_user = User.find(collab.user_id)
    notif_params[:user_id] = accepted_user.id
    project = Project.find(collab.project_id)
    alter_notif.update(description: "#{accepted_user.name}'s was accepted to collaborate on #{project.title}")
    notif_params[:project_id] = project.id
    notif_params[:relation] = "collaborator"
    notif_params[:description] = "You have been accepted to collaborate on #{project.title}!"
    collab
    collab.notifications.create(notif_params)
    redirect_to '/notifications'
  end

  def destroy
    collaboration = Collaboration.find(params[:id])
    project = Project.find(collaboration.project_id)
    project_creator = User.find(project.user_id)
    alter_notif = Notification.find(collaboration.notifications[0].id)
    rejected_user = User.find(collaboration.user_id)
    collaboration.destroy
    if @current_user == project_creator
      notif_params = notification_params
      notif_params[:user_id] = rejected_user.id
      notif_params[:project_id] = project.id
      notif_params[:description] = "You have been denied your request to collaborate on #{project.title}!"
      Notification.create(notif_params)
      alter_notif.update(description: "#{rejected_user.name}'s collaboration request was denied for #{project.title}.")
      redirect_to '/notifications'
    else
      notif_params = notification_params
      notif_params[:user_id] = project_creator.id
      Notification.create(notif_params)
      redirect_to project_path(project.id)
    end
  end

  private

  def collaboration_params
    params.require(:collaboration).permit(:user_id, :project_id, :status)
  end

  def notification_params
    params.require(:notification).permit(:user_id, :project_id, :not_type, :description, :relation)
  end
end



















