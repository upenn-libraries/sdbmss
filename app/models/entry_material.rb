class EntryMaterial < ActiveRecord::Base

  include CertaintyFlags
  include HasPaperTrail

  belongs_to :entry

  validates_presence_of :entry
  validate :observed_or_dropdown

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
    (material || observed_name.to_s) + certainty_flags
  end

  def to_fields
    {material: material}
  end

  private

  def observed_or_dropdown
    if observed_name.blank? && material.blank?
      errors[:base] << "Either an observed value or value from the dropdown are required (or both)"
    end
  end

end
