
# Takes a Version object for Entries or its associated models, and
# creates user-friendly strings for display about the changes made.
class EntryVersionFormatter

  attr_reader :version

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
    'EntryManuscript.entry_id',
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
  ]

  def initialize(version)
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

  # returns an array of strings
  def details
    # cache 'details' b/c this method gets called several times
    if @details == nil

      # TODO: for FK fields to things like names, we should display
      # something more meaningful than just numeric ID

      details = []
      if version.event == 'update'
        version.changeset.each do |field, values|
          if !IGNORE_FIELDS.include?("#{version.item_type}.#{field}")
            details << "#{field.titlecase}: from #{values[0].present? ? values[0] : "(blank)"} to #{values[1]}"
          end
        end
      elsif version.event == 'create'
        version.changeset.each do |field, values|
          value = values[1]
          if !IGNORE_FIELDS.include?("#{version.item_type}.#{field}") && value.present?
            details << "#{field.titlecase}: #{value}"
          end
        end
      elsif version.event == 'destroy'
        obj = version.reify
        obj.attributes.each do |field, value|
          if !IGNORE_FIELDS.include?("#{version.item_type}.#{field}") && value.present?
            details << "#{field.titlecase}: #{value}"
          end
        end
      end
      @details = details
    end
    @details
  end

end
