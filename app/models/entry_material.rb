class EntryMaterial < ActiveRecord::Base
  belongs_to :entry

  MATERIAL_TYPES = [
    ["C", "Clay"],
    ["P", "Paper"],
    ["PY", "Papyrus"],
    ["S", "Silk"],
    ["V", "Parchment"],
  ]

end
