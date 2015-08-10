class User < ActiveRecord::Base

  ROLES = %w[contributor editor admin]

  attr_accessible :username, :email, :password, :password_confirmation if Rails::VERSION::MAJOR < 4

  attr_accessor :login

  has_many :entries, foreign_key: "created_by_id"

  has_many :sources, foreign_key: "created_by_id"

  before_validation :assign_default_role

  # one of the devise class methods above seems to give us
  # "validates_confirmation_of :password" so we don't need it
  # explicitly

  validates :username,
            :uniqueness => {
              :case_sensitive => false
            }

  validates_inclusion_of :role, in: ROLES

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Connects this user object to Blacklights Bookmarks. 
  include Blacklight::User
  include UserFields
  include HasPaperTrail
  include CreatesActivity

  def self.statistics
    results = ActiveRecord::Base.connection.execute("select username, count(*) from users inner join entries on entries.created_by_id = users.id where entries.deleted = 0 group by username")
    results.map do |row|
      {
        username: row[0],
        num_entries: row[1]
      }
    end
  end

  # override
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions).first
    end
  end

  # override devise's mechanism for checking if user is allowed to
  # authenticate. Note that in addition to preventing the user from
  # being able to login, this also de-authorizes any active sessions,
  # so user is immediately kicked out.
  def active_for_authentication?
    super && active
  end

  # override devise's msg to display if user is prevented from logging in
  def inactive_message
    active ? super : "Your account has been de-activated."
  end

  # devise hook
  def after_database_authentication
    Rails.logger.info "#{username} logged in at #{DateTime.now.to_formatted_s(:date_and_time)}"
  end

  def login
    @login || self.username || self.email
  end

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    username
  end

  def role?(role_to_check)
    role == role_to_check
  end

  private

  def assign_default_role
    if !persisted? && role.blank?
      self.role = 'contributor'
    end
  end

end
