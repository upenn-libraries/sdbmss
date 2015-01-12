class EntryMaterial < ActiveRecord::Base
  belongs_to :entry

  MATERIAL_TYPES = [
    ["Bamboo", "Bamboo"],
    ["Clay", "Clay"],
    ["Leather", "Leather"],
    ["Palm leaf", "Palm leaf"],
    ["Paper", "Paper"],
    ["Papyrus", "Papyrus"],
    ["Parchment", "Parchment"],
    ["Silk", "Silk"],
    ["Wood", "Wood"],
    ["Other", "Other"],
  ]

end
