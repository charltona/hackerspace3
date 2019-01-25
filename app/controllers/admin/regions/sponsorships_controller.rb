class Admin::Regions::SponsorshipsController < Admin::SponsorshipsController
  before_action :authenticate_user!
  before_action :check_for_privileges

  def index
    @region = Region.find params[:region_id]
    @sponsorships = @region.sponsorships
  end

  def new
    @sponsorable = Region.find params[:region_id]
    @sponsorship = Sponsorship.new
    search_sponsors unless params[:term].blank?
  end

  def create
    create_new_sponsorship
    if @sponsorship.save
      flash[:notice] = 'New sponsorship created'
      redirect_to admin_region_sponsorships_path @sponsorable
    else
      flash.now[:alert] = @sponsorship.errors.full_messages.to_sentence
      render :new
    end
  end

  private

  def sponsorship_params
    params.require(:sponsorship).permit(:sponsorship_type_id, :sponsor_id)
  end

  def create_new_sponsorship
    @sponsorable = Region.find params[:region_id]
    @sponsorship = @sponsorable.sponsorships.new sponsorship_params
  end

  def check_for_privileges
    return if current_user.sponsor_privileges?

    flash[:alert] = 'You must have valid assignments to access this section.'
    redirect_to root_path
  end

  def search_sponsors
    @sponsor = Sponsor.find_by_name params[:term]
    if @sponsor.present?
      @existing_sponsorship = Sponsorship.find_by sponsor: @sponsor,
                                                  sponsorable: @sponsorable
    else
      @sponsors = Sponsor.search params[:term]
    end
  end
end
