class User < ActiveRecord::Base

  ROLES = %w[contributor editor admin]

  attr_accessible :username, :email, :password, :password_confirmation if Rails::VERSION::MAJOR < 4

  attr_accessor :login

  has_many :entries, foreign_key: "created_by_id"

  has_many :sources, foreign_key: "created_by_id"

  has_many :downloads

  has_many :user_messages, foreign_key: "user_id"
  has_many :private_messages, through: :user_messages

  has_many :notifications
  has_one :notification_setting

  accepts_nested_attributes_for :notification_setting, allow_destroy: false

  before_validation :assign_default_role
  before_create :create_notification_setting

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
  end

  scope :sent_by, -> () { joins(:user_messages).where("user_messages.method = 'From'").distinct }
  scope :sent_to, -> () { joins(:user_messages).where("user_messages.method = 'To'").distinct }

  # Connects this user object to Blacklights Bookmarks. 
  include Blacklight::User
  include UserFields
  include HasPaperTrail
  include CreatesActivity
  extend CSVExportable

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
      self.notification_setting = NotificationSetting.create!(user_id: id, on_update: true, on_comment: true, on_reply: false)
    end
    self.notification_setting["on_#{category}".to_sym]
  end

  def notify(message, category)
    if can_notify(category)
      notifications.create(message: message, category: category)
    end
  end

  #def notifications
  #  messages = private_messages.received.select{ |e| e.unread }.count
  #  exports = downloads.select{ |e| e.status == 1}.count
  #  {total: messages + exports, messages: messages, exports: exports}
  #end

  def self.fields
    fields = super
    fields.delete('name')
    ['username'] + fields + ['fullname', 'email', 'role']
  end

  def self.filters  
    filters = super
    filters.delete('created_by')
    filters.delete('updated_by')
    filters + ['active']
  end

  def search_result_format
    {
      id: id,
      username: username,
      fullname: fullname,
      role: role,
      active: active,
      reviewed: reviewed,
      created_by: created_by.present? ? created_by.username : "(none)",
    }
  end

  private

  def assign_default_role
    if !persisted? && role.blank?
      self.role = 'contributor'
    end
  end

  def create_notification_settings
    self.notification_setting = NotificationSetting.create!
    true
  end

end
