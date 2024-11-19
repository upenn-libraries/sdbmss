module ThreddedNullUserPermissions
  def self.included(base)
    base.before_action :authenticate_user!
  end
end