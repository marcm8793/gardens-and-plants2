class PlantTag < ApplicationRecord
  belongs_to :plant
  belongs_to :tag

  validates :plant_id, uniqueness: { scope: :tag_id, message: 'Nope' }
end
