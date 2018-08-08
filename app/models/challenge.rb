class Challenge < ApplicationRecord
  belongs_to :competition
  belongs_to :region
  has_many :sponsorships, as: :sponsorable
end
