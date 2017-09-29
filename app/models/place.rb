class Place < ActiveRecord::Base

  include UserFields
  include ReviewedByField
  include IndexAfterUpdate
  include HasPaperTrail
  include CreatesActivity
  extend SolrSearchable

  default_scope { where(deleted: false) }

  belongs_to :entry

  belongs_to :reviewed_by, :class_name => 'User'

  has_many :entry_places
  has_many :entries, through: :entry_places

  validates_presence_of :name

  validate do |name_obj|
    if name_obj.name.present? && (!name_obj.persisted? || name_obj.name_changed?)
      if (existing_name = self.class.find_by(name: name_obj.name)).present? && name_obj.id != existing_name.id
        errors[:name] << { message: "Place name is already used by record ##{existing_name.id} for '#{existing_name.name}'", name: { id: existing_name.id, name: existing_name.name } }
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
    string :name
    integer :id
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

  def to_s
    name
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
      created_by: created_by.present? ? created_by.username : "(none)",
      created_at: created_at.present? ? created_at.to_formatted_s(:long) : "",
      updated_by: updated_by.present? ? updated_by.username : "(none)",
      updated_at: updated_at.present? ? updated_at.to_formatted_s(:long) : ""
    }
  end

end
