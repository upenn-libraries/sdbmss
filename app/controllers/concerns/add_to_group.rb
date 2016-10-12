
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
    if ids.present?
      ids = ids.map(&:to_i)
      records = model_class.where(id: ids).select { |record| can? :edit, record }
      records.each do |record|
        GroupRecord.create(record: record, group: group)
      end
    end
    model_class.where(:id => ids).index
    respond_to do |format|
      format.json { render :json => {}, :status => :ok }
    end
  end

  def remove_from_group
    ids = params[:ids]
    group = Group.find(params[:group_id])
    group.group_records.where(:record_type => model_class, :record_id => ids).destroy_all
    model_class.where(:id => ids).index
    respond_to do |format|
      format.json { render :json => {}, :status => :ok }
    end
  end

end
