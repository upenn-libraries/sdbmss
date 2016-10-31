
# Takes a Version object for Entries or its associated models, and
# creates user-friendly strings for display about the changes made.
class EntryVersionFormatter

  attr_reader :version

  # ignore these fields for ALL record types
  GENERIC_IGNORE_FIELDS = [
    'created_by_id',   # redundant, since it is stored with version information anyway
    'created_at',   # likewise
    'updated_by_id',
    'updated_at',
    'id'
  ]

  IGNORE_FIELDS = [
    'Sale.id',
    'Sale.entry_id',
    'SaleAgent.id',
    'SaleAgent.sale_id',
    'Entry.id',
    'Entry.touch_count',
    'Entry.updated_by_id',
    'EntryArtist.id',
    'EntryArtist.entry_id',
    'EntryAuthor.id',
    'EntryAuthor.entry_id',
    'EntryComment.id',
    'EntryComment.entry_id',
    'EntryDate.id',
    'EntryDate.entry_id',
    'EntryLanguage.id',
    'EntryLanguage.entry_id',
    'EntryManuscript.id',
    'EntryMaterial.id',
    'EntryMaterial.entry_id',
    'EntryPlace.id',
    'EntryPlace.entry_id',
    'EntryScribe.id',
    'EntryScribe.entry_id',
    'EntryTitle.id',
    'EntryTitle.entry_id',
    'EntryUse.id',
    'EntryUse.entry_id',
    'Provenance.id',
    'Provenance.entry_id',
    'Comment.commentable_id',
    'Comment.commentable_type'
  ]

  def initialize(version)
    if not EntryTitle.last
      et = EntryTitle.new
      @skip = et.paper_trail_options[:ignore]
    else
      @skip = EntryTitle.last.paper_trail_options[:ignore]
    end
    @version = version
    @details = nil
  end

  # returns string
  def action
    change_type = ''
    case version.event
    when "create"
      change_type = 'added'
    when "update"
      change_type = 'changed'
    when "destroy"
      change_type = 'deleted'
    end

    target = version.item_type
    if version.item_type == 'Entry'
      target = "fields"
    elsif version.item_type.start_with?('Entry')
      target = version.item_type.sub('Entry', '')
    end

    change_type + ' ' + target
  end

  def get_object_not_id(key)
    return key.gsub("_id", "")
  end

  # returns an array of strings
  def details
    # cache 'details' b/c this method gets called several times
    if @details == nil

      # TODO: for FK fields to things like names, we should display
      # something more meaningful than just numeric ID

      if version.respond_to? :count
        details = []
        version.each do |v|
          details += detail (v)
        end
        @details = details
      else
        @details = detail (version)
      end
    end
    @details
  end

  # FIX ME: this needs work, to be both more descriptive and more robust

  def detail (version)
    details = []
    if version.item_type == "EntryManuscript"
      item = EntryManuscript.where(id: version.item_id).first
      if item
        details << "<b>#{item.entry.public_id}</b> has been linked to <b>#{item.manuscript.public_id}</b>"
      else
        details << "<b>EntryManuscript #{version.item_id}</b> was deleted."  
      end
    elsif version.event == 'update'
      skip(version.changeset).each do |field, values|
        if !IGNORE_FIELDS.include?("#{version.item_type}.#{field}") && !GENERIC_IGNORE_FIELDS.include?("#{field}")
          if EntryVersionFormatter.isClass(field)
            f = EntryVersionFormatter.toClass(field)
            if f.exists?(values[0])
              values[0] = f.find(values[0])
            end
            if f.exists?(values[1])
              values[1] = f.find(values[1])
            end
          end
          if values[0].present?
            details << "<b>#{field.titlecase}</b> changed from #{values[0]} to #{values[1]}"
          else
            details << "<b>#{field.titlecase}</b> set to #{values[1]}"
          end
        end
      end
    elsif version.event == 'create'
      skip(version.changeset).each do |field, values|
        value = values[1]
        if !IGNORE_FIELDS.include?("#{version.item_type}.#{field}") && !GENERIC_IGNORE_FIELDS.include?("#{field}") && value.present?
          if EntryVersionFormatter.isClass(field)
            f = EntryVersionFormatter.toClass(field)
            if f.exists?(value)
              value = f.find(value)
            end
          end
          details << "<b>#{field.titlecase}</b> set to #{value}"
        end
      end
    elsif version.event == 'destroy'
      obj = version.reify
      skip(obj.attributes).each do |field, value|
        if !IGNORE_FIELDS.include?("#{version.item_type}.#{field}") && !GENERIC_IGNORE_FIELDS.include?("#{field}") && value.present?
          if EntryVersionFormatter.isClass(field)
            f = EntryVersionFormatter.toClass(field)
            if f.exists?(value)
              value = f.find(value)
            end
          end
          details << "<b>#{field.titlecase}</b> #{value}"
        end
      end
    end
    return details
  end

  def skip (h)
    h.select { |key, val| !@skip.include?(key) }
  end

  def self.toClass (field)
    if ['author_id', 'artist_id', 'scribe_id', 'source_agent_id', 'sale_agent_id', 'provenance_agent_id', 'agent_id', 'institution_id'].include? field
      return Name
    elsif ['created_by_id', 'updated_by_id', 'approved_by_id', 'reviewed_by_id'].include? field
      return User
    elsif ['entry_id']
      return Entry
    else
      return field.gsub('_id', '').capitalize.classify.constantize
    end
  end

  def self.isClass (field)
    return field.include?('_id') && field.downcase != "viaf_id"
  end

end
