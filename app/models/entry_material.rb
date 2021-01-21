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
    map = {
      model_class: "entry_materials",
      id: id,
      fields: {}
    }

    map[:fields][:material]               = format_triple_object material,               :string
    map[:fields][:observed_name]          = format_triple_object observed_name,          :string
    map[:fields][:entry_id]               = format_triple_object entry_id,               :uri,    'https://sdbm.library.upenn.edu/entries/'
    map[:fields][:order]                  = format_triple_object order,                  :integer
    map[:fields][:supplied_by_data_entry] = format_triple_object supplied_by_data_entry, :boolean
    map[:fields][:uncertain_in_source]    = format_triple_object uncertain_in_source,    :boolean

    map
  end


  private

  def observed_or_dropdown
    if observed_name.blank? && material.blank?
      errors[:base] << "Either an observed value or value from the dropdown are required (or both)"
    end
  end

end
