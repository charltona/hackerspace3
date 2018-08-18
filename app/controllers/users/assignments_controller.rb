class Users::AssignmentsController < ApplicationController

  def update
    @assignment = Assignment.find(params[:id])
    @assignment.update(title: TEAM_MEMBER)
    redirect_to team_path(@assignment.assignable)
  end

  def destroy
    @assignment = Assignment.find(params[:id])
    @assignment.destroy
    flash[:notice] = 'Invitation Destroyed'
    redirect_to manage_account_path
  end
end
