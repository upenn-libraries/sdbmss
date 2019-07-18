class EntryMaterial < ActiveRecord::Base

  include CertaintyFlags
  include HasPaperTrail

  include TellBunny

  belongs_to :entry

  validates_presence_of :entry
  validate :observed_or_dropdown
  validates_length_of :material, :minimum => 0, :maximum => 255, :allow_blank => true

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

  def display_value
    [material ? material : nil, observed_name.present? ? "(#{observed_name})" : nil].reject(&:blank?).join(" ")
  end

  def facet_value
    material ? material : nil
  end

  def to_s
    display_value
  end

  def to_rdf
    {
      model_class: "entry_materials",
      id: id,
      fields: {
        material: "'''#{material}'''",
        observed_name: "'''#{observed_name}'''",
        entry_id: "<https://sdbm.library.upenn.edu/entries/#{entry_id}>",
        order: "'#{order}'^^xsd:integer",
        supplied_by_data_entry: "'#{supplied_by_data_entry}'^^xsd:boolean",
        uncertain_in_source: "'#{uncertain_in_source}'^^xsd:boolean"
      }
    }
  end


  private

  def observed_or_dropdown
    if observed_name.blank? && material.blank?
      errors[:base] << "Either an observed value or value from the dropdown are required (or both)"
    end
  end

end
