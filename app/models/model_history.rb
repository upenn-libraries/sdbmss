
require 'set'

# Represents the history of changes made to a model object, including
# its associations.
class ModelHistory

  # Represents a group of changes made to an model; in workflow terms,
  # this represents a set of edits made by a user in a single database
  # transaction.
  class ChangeSet

    attr_reader :date, :user_id, :changes, :transaction_id

    def initialize(date, user_id, changes, transaction_id)
      @date = date
      @user_id = user_id
      @changes = changes
      @transaction_id = transaction_id
    end

    def user
      user_id.present? ? User.find(user_id) : nil
    end

  end

  # Represents an atomic change (ie. change made to a field) in a
  # model object or one of its associations
  class Change

    attr_reader :change_type, :object_class, :field, :values

    def initialize(change_type, object_class, field, values)
      @change_type = change_type
      @object_class = object_class
      @field = field
      @values = values
    end

  end

  attr_reader :changesets

  def initialize(model_object)
    @model_object = model_object
    @changesets = []
    load
  end

  private

  IGNORE_FIELDS = ['updated_at', 'touch_count']

  def load

    # TODO: this doesn't yet account for:
    # - changes to event_agents
    # - deletion of Events or any associated entries

    # get all the model object's associations that have paper trail
    # enabled. this is an array of AssociationReflection objects.
    associations = @model_object.class.reflect_on_all_associations.select do |assoc|
      # reject "has_many through" relations
      assoc.collection? && !assoc.options.has_key?(:through) && assoc.klass.paper_trail_enabled_for_model?
    end

    # keep running list of transaction ids of ANY version of anything
    # we find: this allows us to get 'destroy' events (those records
    # wouldn't be attached to anything otherwise)
    transaction_ids = Set.new

    all_versions = [].concat(@model_object.versions)

    transaction_ids.merge(@model_object.versions.map(&:transaction_id))

    # Is this really necessary???
    associations.each do |association|
      @model_object.send(association.name).each do |related_object|
        all_versions.concat(related_object.versions)
        transaction_ids.merge(related_object.versions.map(&:transaction_id))
      end
    end

    versions = PaperTrail::Version.where("transaction_id IN (?)", transaction_ids)
    versions.each do |v|
      if !all_versions.include?(v)
        all_versions << v
      end
    end

    # group versions into ChangeSets
    groups = all_versions.group_by { |o| o.transaction_id }

    @changesets = groups.map do |key, versions|
      changes = []
      date = nil
      versions.each do |version|
        if version.event == 'destroy'
          changes << Change.new(version.event, version.item_type, 'id', [version.item_id, version.item_id])
        else
          version.changeset.each do |field, values|
            if !IGNORE_FIELDS.include?(field)
              changes << Change.new(version.event, version.item_type, field, values)
            end
          end
        end
        updated_at = version.reify.try(:updated_at)
        puts "#{version.item_type} updated_at=#{updated_at}"
        if date.nil? || (updated_at.present? && updated_at > date)
          date = updated_at
        end
      end
      # TODO: this is broken b/c PaperTrail uses the object's updated_at timestamp for the created_at field of Version
      ChangeSet.new(date, versions.first.whodunnit, changes, key)
    end

    #@changesets.sort! { |x,y| x.date <=> y.date }
    @changesets.sort! { |x,y| x.transaction_id <=> y.transaction_id }
    #@changesets.reverse!
  end

end
