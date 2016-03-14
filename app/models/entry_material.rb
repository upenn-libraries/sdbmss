class EntryMaterial < ActiveRecord::Base

  include CertaintyFlags
  include HasPaperTrail

  belongs_to :entry

  validates_presence_of :entry
  validates_presence_of :material

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

  def to_fields
    {material: material}
  end

end
