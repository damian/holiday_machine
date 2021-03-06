class User < ActiveRecord::Base

  devise :invitable, :database_authenticatable, :confirmable, :lockable, :recoverable,
         :rememberable, :registerable, :trackable, :timeoutable, :validatable,
         :token_authenticatable

  ## Callbacks
  before_update :add_inviting_manager
  after_create :create_allowance
  after_destroy :delete_all_allowances

  ## Associations
  belongs_to :user_type
  has_many :user_days
  has_many :vacations
  has_many :user_days_for_years

  ## Validations
  validates_presence_of :email, :forename, :surname, :user_type
  validates_presence_of :invite_code, :on => :create
  validates_each :invite_code, :on => :create do |record, attr, value|
    record.errors.add attr, "Please enter correct invite code" unless value && value == "Sage1nvite00"
  end

  attr_accessor :invite_code
  attr_accessible :email, :password, :password_confirmation, :forename, :surname, :user_type_id, :manager_id, :invite_code, :invitation_token, :remember_me

  ## Scopes
  #Includes own manager
  #TODO should this not be and rather than or
  scope :get_team_users, lambda { |manager_id| where('(manager_id = ? or id = ?) and confirmed_at is not null', manager_id, manager_id) }

  ## Instance methods
  def full_name
    self[:forename] + " " + self[:surname]
  end

  def get_holiday_allowance_for_dates date_from, date_to
    holiday_year = HolidayYear.where('date_start<=? and date_end>=?', date_from, date_to).first
    unless holiday_year.nil? #If a holiday isn't in a year( maybe straddles year) then returns nil
      allowance = UserDaysForYear.where("user_id = ? and holiday_year_id = ?", self.id, holiday_year.id).first
    end
    allowance
  end

  def get_holiday_allowance_for_selected_year year
    UserDaysForYear.where("user_id = ? and holiday_year_id = ?", self.id, year.id).first
  end

  def get_holiday_allowance #For current year
    today = Date.today
    holiday_year = HolidayYear.where('date_start<=? and date_end>=?', today, today).first
    allowance = UserDaysForYear.where("user_id = ? and holiday_year_id = ?", self.id, holiday_year.id).first
    allowance
  end

  def create_allowance
    today = Date.today
    holiday_years = HolidayYear.all
    holiday_years.each do |year|
      days_allowed = UserDaysForYear.new(:user_id => self.id, :holiday_year_id => year.id)
      days_allowed.days_remaining=25
      days_allowed.save
    end
  end

  def delete_all_allowances
    UserDaysForYear.destroy(:user_id => self.id)
  end

  def user_days_for_selected_year year
    UserDay.where(:user_id => self.id, :holiday_year_id => year.id)
  end

  def add_inviting_manager
    unless invited_by_id.blank?
      self.manager_id = self.invited_by_id
      self.invited_by_id = nil
    end
  end

end
