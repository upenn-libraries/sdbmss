class Place < ActiveRecord::Base

  include UserFields
  include ReviewedByField
  include IndexAfterUpdate
  include HasPaperTrail
  include CreatesActivity
  extend SolrSearchable

  include TellBunny

  default_scope { where(deleted: false) }

  belongs_to :entry

  belongs_to :reviewed_by, :class_name => 'User'

  has_many :entry_places
  has_many :entries, through: :entry_places

  validates_presence_of :name

  belongs_to :parent, class_name: "Place"
  has_many :children,  class_name: "Place", foreign_key: "parent_id", :dependent => :restrict_with_error

  #has_many :names, class_name: "Name", foreign_key: "associated_place_id", :dependent => :restrict_with_error

  has_many :name_places, :dependent => :destroy
  has_many :names, -> {distinct}, through: :name_places

  has_many :comments, as: :commentable

  validate do |name_obj|
    if name_obj.name.present? && (!name_obj.persisted? || name_obj.name_changed?)
      if (existing_name = self.class.find_by(name: name_obj.name)).present? && name_obj.id != existing_name.id
        errors[:Name] << "Place name is already used by record #{existing_name.public_id} -> '#{existing_name.name}'"
      end
    end
    if (name_obj.authority_id.present? && name_obj.authority_source.present?)
      if (existing_names = self.class.where(authority_source: name_obj.authority_source, authority_id: name_obj.authority_id).where.not(id: name_obj.id)).count > 0
        errors[:Authority] << "Place authority ID is already used by record #{existing_names.first.public_id} -> '#{existing_names.first.name}'"
      end
    end
    n = name_obj
    while (n = n.parent) do
      if n.id == name_obj.id
        errors[:Circular] << " - Please don't assign a place to be the parent of a chain that includes itself."
      end
    end
  end

  searchable :unless => :deleted do
    string :created_by do
      created_by ? created_by.username : ""
    end
    string :updated_by do
      updated_by ? updated_by.username : ""
    end
    text :created_by do
      created_by ? created_by.username : ""
    end
    text :updated_by do
      updated_by ? updated_by.username: ""
    end
    text :name, :more_like_this => true
    text :evidence, :as => :evidence_text
    string :evidence
    string :name
    integer :id
    string :authority_id
    string :authority_source
    float :latitude
    float :longitude
    string :parent do
      parent.nil? ? nil : parent.name
    end
    boolean :reviewed
    boolean :problem
    integer :created_by_id
    integer :entries_count
    date :created_at
    date :updated_at
    boolean :reviewed
  end

  def entries_to_index_on_update
    Entry.with_associations.joins(:entry_places).where({ entry_places: { place_id: id} })
  end

  def self.filters
    super + [
      ["Authority Id", "authority_id"],
      ["Authority Source", "authority_source"],
      ["Problem", "problem"],
      ["Parent", "parent"],
      ["Latitude", "latitude"],
      ["Longitude", "longitude"]
    ]
  end

  def self.fields
    super + [
      ["Other Info", "evidence"]
    ]
  end

  def ancestors
    if parent
      [name] + parent.ancestors
    else
      [name]
    end
  end

  def to_s
    [name, parent ? parent.to_s : nil].reject(&:blank?).join(", ")
  end

  def public_id
    SDBMSS::IDS.get_public_id_for_model(self.class, id)
  end

  def search_result_format
    {
      id: id,
      public_id: public_id,
      name: name,
      entries_count: entries_count,
      reviewed: reviewed,
      problem: problem,
      parent: parent ? {id: parent.id, name: parent.name} : nil,
      latitude: latitude,
      longitude: longitude,
      authority_id: authority_id,
      evidence: evidence,
      created_by: created_by.present? ? created_by.username : "(none)",
      created_at: created_at.present? ? created_at.to_formatted_s(:long) : "",
      updated_by: updated_by.present? ? updated_by.username : "(none)",
      updated_at: updated_at.present? ? updated_at.to_formatted_s(:long) : "",
      authority_source: authority_source
    }
  end

  def to_rdf
    map = {
      model_class: "places",
      id: id,
      fields: {}
    }

    map[:fields][:name]             = "'''#{name.to_s.gsub("'", "")}'''"                     if name.present?
    map[:fields][:authority_id]     = "'''#{authority_id}'''"                                if authority_id.present?
    map[:fields][:authority_source] = "'''#{authority_source}'''"                            if authority_source.present?
    map[:fields][:parent_id]        = "<https://sdbm.library.upenn.edu/places/#{parent_id}>" if parent_id.present?
    map[:fields][:latitude]         = "'#{latitude}'^^xsd:decimal"                           if latitude.present?
    map[:fields][:longitude]        = "'#{longitude}'^^xsd:decimal"                          if longitude.present?
    map[:fields][:deleted]          = "'#{deleted}'^^xsd:boolean"                            unless deleted.nil?

    map
  end

end