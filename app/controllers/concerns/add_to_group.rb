
# Provides #mark_as_reviewed action that accepts an object with key
# 'ids' whose value is an array of entity ids.
module AddToGroup

  extend ActiveSupport::Concern

  def self.included(base)
    if !base.method_defined?(:model_class)
      raise "method #model_class not found in base class that's trying to include AddToGroup"
    end
  end

  def add_to_group
    ids = params[:ids]
    group = Group.find(params[:group_id])
    editable = params[:editable] == "true"
    response = ""
    uneditable = 0
    already_added = 0
    if ids.present?
      ids = ids.map(&:to_i)
      records = model_class.where(id: ids)#.select {|r| can? :edit, r }
      records.each do |record|
        if can? :edit, record
          if GroupRecord.create(record: record, group: group, editable: editable).id
          else
            already_added += 1
          end
        else
          if GroupRecord.create(record: record, group: group, editable: false).id
            if editable != false
              uneditable += 1
            end
          else
            already_added += 1
          end
        end
      end
      total = ids.count - uneditable - already_added
      response += "You successfully added #{total} #{'record'.pluralize(total)} to #{group.name}."
      if already_added > 0
        response += "<br>#{already_added} #{'record'.pluralize(already_added)} are already members of #{group.name}.".html_safe
      end
      if uneditable > 0
        response += "<br>You do not have permission to make #{uneditable} #{'record'.pluralize(uneditable)} editable by #{group.name}.  They have been added as observable records only.".html_safe
      end
    end
    SDBMSS::IndexJob.perform_later(Entry.to_s, ids)
    respond_to do |format|
      format.json { render :json => {response: response}, :status => :ok }
      format.html { redirect_to entry_path(ids.first) }
    end
  end

  def remove_from_group
    ids = params[:ids]
    group = Group.find(params[:group_id])
    count = group.group_records.where(:record_type => model_class, :record_id => ids).count
    group.group_records.where(:record_type => model_class, :record_id => ids).destroy_all
    SDBMSS::IndexJob.perform_later(Entry.to_s, ids)
    response = "#{count} #{'record'.pluralize(count)} removed from '#{group.name}'"
    unpermitted = ids.count - count
    if unpermitted > 0
      response += "You do not have permission to change group status for #{unpermitted} #{'record'.pluralize(unpermitted)}"
    end
    respond_to do |format|
      format.json { render :json => {response: response}, :status => :ok }
      format.html { redirect_to entry_path(ids.first) }
    end
  end

end
