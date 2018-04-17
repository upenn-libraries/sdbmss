class User < ActiveRecord::Base

  ROLES = %w[contributor editor super_editor admin]

  attr_accessible :username, :email, :password, :password_confirmation if Rails::VERSION::MAJOR < 4

  attr_accessor :login

  has_many :group_users
  has_many :groups, through: :group_users

  has_many :entries, foreign_key: "created_by_id"
  has_many :sources, foreign_key: "created_by_id"

  has_many :downloads

  has_many :user_messages, -> { where(:deleted => false) }, foreign_key: "user_id"
  has_many :private_messages, through: :user_messages
  has_many :sent_messages, foreign_key: "created_by_id", class_name: "PrivateMessage"

  #has_many :sent_messages, foreign_key: "created_by_id", class_name: "PrivateMessage"

  has_many :notifications
  has_one :notification_setting

  has_many :ratings
  has_many :rated, -> { distinct }, through: :ratings

  has_many :watches
  has_many :watched_entries, -> { distinct }, through: :watches, source: :watched, source_type: "Entry"
  has_many :watched_sources, -> { distinct }, through: :watches, source: :watched, source_type: "Source"
  has_many :watched_names, -> { distinct }, through: :watches, source: :watched, source_type: "Name"
  has_many :watched_manuscripts, -> { distinct }, through: :watches, source: :watched, source_type: "Manuscript"

  accepts_nested_attributes_for :notification_setting, allow_destroy: false

  before_validation :assign_default_role
  before_create :create_notification_setting

  has_many :dericci_games, foreign_key: "created_by_id"
  has_many :dericci_game_records, through: :dericci_games
  has_many :played_records, -> { distinct }, through: :dericci_game_records, source: :dericci_record

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

  # allow solr indexing/searching of usernames
  searchable do
    integer :id
    text :username
    string :username
    text :fullname
    string :fullname
    text :email
    string :email
    text :role
    string :role
    boolean :reviewed
    boolean :active
    date :created_at
    date :updated_at
    date :last_sign_in_at
  end

  # Connects this user object to Blacklights Bookmarks. 
  include Blacklight::User
  include UserFields
  include HasPaperTrail
  #include CreatesActivity
  extend SolrSearchable

  def all_messages
    (private_messages | sent_messages)
  end

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

  def new_notifications
    notifications.where(active: true)
  end

  def name
    username
  end

  def admin
    role == "admin"
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
    fullname.present? ? fullname : username
  end

  def role?(role_to_check)
    role == role_to_check
  end

  def tags
    s = {}
    bookmarks.each do |bookmark|
      tags = bookmark.tags.split(',') unless bookmark.tags.nil?
      tags.to_a.each do |tag|
        if s.include?(tag)
          s[tag] += 1
        else
          s[tag] = 1
        end
      end
    end
    s
  end

  def can_notify(category)
    if !self.notification_setting
      self.notification_setting = NotificationSetting.create!(user_id: id)
    end
    self.notification_setting["on_#{category}".to_sym]
  end

  def can_email(category)
    if !self.notification_setting
      self.notification_setting = NotificationSetting.create!(user_id: id)
    end
    self.notification_setting["email_on_#{category}".to_sym]
  end

  # 12-06-17 fix me: if emails are set, but not notifications, 'n' will be undefined
  def notify(title, record, category)
    n = notifications.new(title: title, notified: record, category: category)
    if can_notify(category)
      n.save!
    end
    if can_email(category)
      # DelayedJob doesn't like in-memory-only active-records, so I create a generic object here...
      require 'ostruct'
      m = OpenStruct.new(title: title, notified: record, category: category, user: n.user)
      NotificationMailer.delay.notification_email(m)
    end
  end

  # override default searchable fields and results

  def self.fields
    [
      ["Username", 'username'],
      ["Full Name", 'fullname'], 
      ["Email", 'email'],
      ["User Level", 'role']
    ]
  end

  def self.filters  
    [
      ["Id", "id"],
      ["Active", "active"]
    ]
  end

  def self.dates
    dates = super
    dates + [["Last Seen", 'last_sign_in_at']]
  end

  def search_result_format
    {
      id: id,
      username: username,
      fullname: fullname,
      role: role,
      groups: groups.map{ |group| [group.id, group.name] }.to_s,
      active: active,
      reviewed: reviewed,
      created_by: created_by.present? ? created_by.username : "(none)",
      created_at: created_at.present? ? created_at.to_formatted_s(:long) : "",
      last_sign_in_at: last_sign_in_at.present? ? last_sign_in_at.to_formatted_s(:long) : ""
    }
  end

  def preview
    %(
      You have a new user!  Please welcome: #{username}.
    )
  end

  private

  def assign_default_role
    if !persisted? && role.blank?
      self.role = 'contributor'
    end
  end

  def create_notification_settings
    self.notification_setting = NotificationSetting.create!(user_id: self.id)
    true
  end

end
