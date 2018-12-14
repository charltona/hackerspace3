class Admin::Teams::EntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :check_for_privileges

  def new
    @team = Team.find(params[:team_id])
    @entry = @team.entries.new
    @challenges = @team.available_challenges(params[:challenge_type])
  end

  def edit
    @entry = Entry.find(params[:id])
    @team = @entry.team
    @challenge = @entry.challenge
    @checkpoints = (@team.admin_available_checkpoints(@challenge) << @entry.checkpoint).uniq
  end

  def update
    @entry = Entry.find(params[:id])
    @challenge = @entry.challenge
    @team = @entry.team
    @checkpoints = (@team.admin_available_checkpoints(@challenge) << @entry.checkpoint).uniq
    handle_update
  end

  def create
    @team = Team.find(params[:team_id])
    @entry = @team.entries.new(entry_params)
    @entry.checkpoint_id = params[:checkpoint_id]
    handle_create
  end

  def destroy
    @team = Team.find(params[:team_id])
    @entry = Entry.find(params[:id])
    @entry.destroy
    flash[:notice] = 'Challenge Entry Removed'
    redirect_to admin_team_path(@team)
  end

  private

  def entry_params
    params.require(:entry).permit(:challenge_id, :justification, :checkpoint_id)
  end

  def check_for_privileges
    return if current_user.admin_privileges?

    flash[:alert] = 'You must have valid assignments to access this section.'
    redirect_to root_path
  end

  def handle_create
    if @entry.save
      flash[:notice] = 'New Challenge Entry Created'
      redirect_to admin_team_path(@team)
    else
      handle_create_fail
    end
  end

  def handle_create_fail
    @challenges = @team.available_challenges(params[:challenge_type])
    flash[:alert] = @entry.errors.full_messages.to_sentence
    render :new, challenge_type: params[:challenge_type], checkpoint_id: params[:checkpoint_id]
  end

  def handle_update
    if @entry.update(entry_params)
      flash[:notice] = 'Entry Updated Successfully'
      redirect_to admin_team_path(@team)
    else
      flash[:alert] = @entry.errors.full_messages.to_sentence
      render :edit
    end
  end
end
