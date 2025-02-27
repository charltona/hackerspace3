class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user

    @assignments = @user.assignments.where competition: @competition
    @assignment_titles = @assignments.pluck :title

    @event_assignment = @user.event_assignment @competition

    @registrations_present = @event_assignment.registrations.exists?
    @connection_registrations = @event_assignment.registrations.connection_events.preload event: :region
    @conference_registrations = @event_assignment.registrations.conference_events.preload event: :region
    @competition_registrations = @event_assignment.registrations.competition_events.preload event: :region
    @award_registrations = @event_assignment.registrations.award_events.preload event: :region

    @sponsor_contact_assignments = @assignments.sponsor_contacts.preload :assignable

    @judging_assignments = @assignments.judges

    @favourite_teams = @event_assignment.favourite_teams.published.preload :event, :current_project

    @joined_teams = @user.joined_teams.competition(@competition).preload :event, :current_project, :region
    @invited_team_assignments = @user.invited_team_assignments.where(competition: @competition)

    @public_winning_entries = has_public_winning_entries? @competition
    @region_privileges = @user.region_privileges? @competition

    @participating_competition_event = @user.participating_competition_event @competition
    @time_zone = @participating_competition_event&.region&.national_time_zone
  end

  def edit
    @user = current_user
  end


  def update
    @user = current_user
    if params[:user].nil?
      redirect_to root_path
    else
      handle_update_user
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :tshirt_size,
      :govhack_contact,
      :dietary_requirements,
      :govhack_img,
      :bsb,
      :acc_number,
      :acc_name,
      :branch_name,
      *user_permitted_attributes
    )
  end

  def user_permitted_attributes
    %i[
      full_name
      preferred_name
      organisation_name
      phone_number
      region
      registration_type
      slack
      mailing_list
      challenge_sponsor_contact_place
      challenge_sponsor_contact_enter
      my_project_sponsor_contact
      me_govhack_contact
    ]
  end

  def handle_update_user
    @user.update user_params unless params.nil?
    if @user.save
      account_update_successfully
    else
      render 'edit'
    end
  end

  def account_update_successfully
    if params[:banking].present?
      handle_bank_update
    else
      handle_personal_details
    end
  end

  def handle_bank_update
    BankMailer.notify_finance(@user).deliver_later
    flash[:notice] = 'Your banking details have been updated.'
    redirect_to manage_account_path
  end

  def handle_personal_details
    flash[:notice] = 'Your personal details have been updated.'
    redirect_to manage_account_path
  end

  def has_public_winning_entries?(competition)
    @user.winning_entries.competition(competition).preload(challenge: :region).each do |entry|
      return true if entry.challenge.region.awards_released?
    end
    false
  end
end
