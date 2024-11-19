
require 'set'

# Represents the history of changes made to a model object, including its
# associations.
#
# This feature makes use of (and depends on!) PaperTrail storing a
# database transaction_id for a set of changes across tables, which we
# treat as a single 'ChangeSet'.
class ModelHistory

  # Encapsulates a group of changes that we consider a single
  # operation.
  class ChangeSet

    attr_reader :date, :user_id, :versions

    def initialize(date, user_id, versions)
      @date = date
      @user_id = user_id
      @versions = versions
    end
=begin REMOVE
    def user
      user_id.present? ? User.find(user_id) : nil
    end
=end

  end

  attr_reader :changesets

  def initialize(model_object)
    @model_object = model_object
    @changesets = []
    load
  end

  # returns Array of all the Users who have ever touched this object
  def editors
    changesets.map(&:user_id).select(&:present?).uniq.map { |user_id| User.find(user_id) }
  end

  private

  def load

    # create list of ALL transaction ids of ANY version of model
    # object, so we can grab Version records for the associations too
    transaction_ids = Set.new

    all_versions = [].concat(@model_object.versions)

    transaction_ids.merge(@model_object.versions.map(&:transaction_id))

    versions = PaperTrail::Version.where("transaction_id IN (?)", transaction_ids)
    versions.each do |v|
      if !all_versions.include?(v)
        all_versions << v
      end
    end

    # group by transaction_id into ChangeSets
    groups = all_versions.group_by { |o| o.transaction_id }

    @changesets = groups.map do |key, versions|
      ChangeSet.new(versions.first.created_at, versions.first.whodunnit, versions)
    end

    @changesets.sort! { |x,y| x.date <=> y.date }
    @changesets.reverse!
  end

end
