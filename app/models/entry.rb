class Entry < ApplicationRecord
  belongs_to :checkpoint
  belongs_to :challenge
  belongs_to :team

  has_one :competition, through: :team
  has_one :region, through: :challenge

  has_many :scorecards, dependent: :destroy, as: :judgeable

  validates :justification, presence: true
  validates :team_id, uniqueness: {
    scope: :challenge_id,
    message: 'Teams are not able to enter the same Challenge twice.'
  }
  validates :award, allow_nil: true, inclusion: { in: AWARD_NAMES }
  validate :entries_must_not_exceed_max_regional_allowed_for_checkpoint,
           :entries_must_not_exceed_max_national_allowed_for_checkpoint,
           :teams_cannot_enter_regional_challenges_from_regions_other_than_their_own,
           on: :create

  after_create :update_eligible

  scope :regional, lambda {
    joins(:region).where(regions: { category: Region::REGIONAL })
  }
  scope :national, lambda {
    joins(:region).where(
      regions: { category: [Region::INTERNATIONAL, Region::NATIONAL] }
    )
  }
  scope :winners, -> { where award: WINNER }
  scope :competition, lambda { |competition|
    joins(challenge: :region).where(regions: { competition: competition })
  }

  # Checks that a project has enough information entered for the entry to be
  # marked eligible, and then marks accordingly.
  def update_eligible(project = nil)
    project = team.current_project if project.nil?
    update(
      eligible: project.data_story.present? &&
      project.video_url.present? &&
      project.source_code_url.present?
    )
  end

  # Checks that a team has not entered the maximum number of regional challenges
  # at a given checkpoint.
  def entries_must_not_exceed_max_regional_allowed_for_checkpoint
    return if challenge.region.international?

    current_count = team.regional_challenges(checkpoint).count
    max_allowed = checkpoint.max_regional_challenges
    return unless current_count >= max_allowed

    errors.add(
      :checkpoint_id,
      'Maximum Regional Challenges already entered for this Checkpoint'
    )
  end

  # Checks that a team has not entered the maximum number of national challenges
  # at a given checkpoint.
  def entries_must_not_exceed_max_national_allowed_for_checkpoint
    return unless challenge.region.international?

    current_count = team.national_challenges(checkpoint).count
    max_allowed = checkpoint.max_national_challenges
    return unless current_count >= max_allowed

    errors.add(
      :checkpoint_id,
      'Maximum National Challenges already entered for this Checkpoint'
    )
  end

  # Checks if the regional challenge a team is entering is a challenge in their
  # region.
  def teams_cannot_enter_regional_challenges_from_regions_other_than_their_own
    challenge_region = challenge.region
    return if challenge_region.international?

    errors.add(:checkpoint_id, 'Teams are not able to enter Challenges in Regions other than their own') if team.region != challenge_region
  end

  # Returns the average score obtained across judges of a challenge.
  # ENHANCEMENT: Probably not very DB efficient.
  def average_score
    cards = Scorecard.where(judgeable: self)
    total_score = 0
    voted = 0
    cards.each do |card|
      next if (score = card.total_score).nil?

      total_score += score
      voted += 1
    end
    return (total_score / voted) unless voted.zero?
  end

  # Returns a count of the number of judges that have completed votes for an
  # entry.
  # ENHANCEMENT: Probably not very DB efficient.
  def judges_voted
    cards = Scorecard.where(judgeable: self)
    voted = 0
    cards.each do |card|
      next if card.total_score.nil?

      voted += 1
    end
    voted
  end

  # Returns on objects of a teams challenge entries.
  # ENHANCEMENT: Not needed, move to active record preload.
  def self.team_id_entries(entries)
    entries = where(id: entries.uniq) if entries.class == Array
    id_entries = {}
    entries.each { |entry| id_entries[entry.team_id] = entry }
    id_entries
  end
end
