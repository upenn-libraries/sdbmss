class EntryMaterial < ActiveRecord::Base

  include CertaintyFlags

  belongs_to :entry

  validates_presence_of :entry
  validates_presence_of :material

  has_paper_trail skip: [:created_at, :updated_at]

  MATERIAL_TYPES = [
    ["Bamboo", "Bamboo"],
    ["Bark", "Bark"],
    ["Clay", "Clay"],
    ["Leaf", "Leaf"],
    ["Leather", "Leather"],
    ["Mica", "Mica"],
    ["Palm leaf", "Palm leaf"],
    ["Paper", "Paper"],
    ["Papyrus", "Papyrus"],
    ["Parchment", "Parchment"],
    ["Silk", "Silk"],
    ["Skin", "Skin"],
    ["Wax", "Wax"],
    ["Wood", "Wood"],
    ["Other", "Other"],
  ]

  def to_s
    (material || "") + certainty_flags
  end

end
