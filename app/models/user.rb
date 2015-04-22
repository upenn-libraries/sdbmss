class User < ActiveRecord::Base

  ROLES = %w[contributor editor admin]

  attr_accessible :username, :email, :password, :password_confirmation if Rails::VERSION::MAJOR < 4

  attr_accessor :login

  has_many :entries, foreign_key: "created_by_id"

  has_many :sources, foreign_key: "created_by_id"

  before_validation :assign_default_role

  def login
    @login || self.username || self.email
  end

  # Connects this user object to Blacklights Bookmarks. 
  include Blacklight::User

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # one of the devise class methods above seems to give us
  # "validates_confirmation_of :password" so we don't need it
  # explicitly

  validates :username,
            :uniqueness => {
              :case_sensitive => false
            }

  validates_inclusion_of :role, in: ROLES

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    username
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
