
# Represents the history of changes made to an Entry, including its
# associations.
class EntryHistory

  # Represents a group of changes made to an entry; in workflow terms,
  # this represents a set of edits made by a user in a single database
  # transaction.
  class ChangeSet

    attr_reader :date, :user_id, :changes

    def initialize(date, user_id, changes)
      @date = date
      @user_id = user_id
      @changes = changes
    end

    def user
      user_id.present? ? User.find(user_id) : nil
    end

  end

  # Represents an atomic change (ie. change made to a field) in an
  # Entry or one of its associations
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

  def initialize(entry)
    @entry = entry
    @changesets = []
    load
  end

  private

  def load

    # TODO: this doesn't yet account for:
    # - changes to event_agents
    # - deletion of Events or any associated entries

    # get all the entry's associations that have paper trail
    # enabled. this is an array of AssociationReflection objects.
    associations = Entry.reflect_on_all_associations.select do |assoc|
      assoc.collection? && assoc.klass.paper_trail_enabled_for_model?
    end

    all_versions = [].concat(@entry.versions)

    associations.each do |association|
      puts "doing #{association}"
      @entry.send(association.name).each do |related_object|
        all_versions.concat(related_object.versions)
      end
    end

    # group versions into ChangeSets
    groups = all_versions.group_by { |o| o.transaction_id }

    @changesets = groups.map do |key, versions|
      changes = []
      versions.each do |version|
        version.changeset.each do |field, values|
          changes << Change.new(version.event, version.item_type, field, values)
        end
      end
      ChangeSet.new(versions.first.created_at, versions.first.whodunnit, changes)
    end

    @changesets.sort! { |x,y| x.date <=> y.date }
    @changesets.reverse!
  end

end
