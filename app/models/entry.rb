class Entry < ApplicationRecord
  belongs_to :team
  belongs_to :checkpoint
  belongs_to :challenge
  has_many :challenge_scorecards, dependent: :destroy

  validates :justification, presence: true

  validates :team_id, uniqueness: { scope: :challenge_id,
                                    message: 'Teams are not able to enter the same Challenge twice.' }

  validate :entries_must_not_exceed_max_regional_allowed_for_checkpoint,
           :entries_must_not_exceed_max_national_allowed_for_checkpoint

  def entries_must_not_exceed_max_regional_allowed_for_checkpoint
    return unless challenge.region.parent_id.nil?
    current_count = team.regional_challenges(checkpoint).count
    max_allowed = checkpoint.max_regional_challenges
    if current_count == max_allowed
      errors.add(:checkpoint_id, 'Maximum Regional Challenges already entered for this Checkpoint')
    end
  end

  def entries_must_not_exceed_max_national_allowed_for_checkpoint
    return if challenge.region.parent_id.nil?
    current_count = team.national_challenges(checkpoint).count
    max_allowed = checkpoint.max_national_challenges
    if current_count == max_allowed
      errors.add(:checkpoint_id, 'Maximum National Challenges already entered for this Checkpoint')
    end
  end

  def average_score
    cards = ChallengeScorecard.where(entry: self)
    total_score = 0
    voted = 0
    cards.each do |card|
      next if (score = card.total_score).nil?
      total_score += score
      voted += 1
    end
    return (total_score / voted) unless voted.zero?
  end

  def judges_voted
    cards = ChallengeScorecard.where(entry: self)
    voted = 0
    cards.each do |card|
      next if card.total_score.nil?
      voted += 1
    end
    voted
  end
end
