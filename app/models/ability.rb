class Ability
  include CanCan::Ability

  # This gets called on-demand immediately before a permission check
  # happens
  def initialize(user)

    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

    user ||= User.new

    # we don't do role inheritance b/c I have a sneaking feeling we
    # will want more fine-grained control for our roles as the system
    # grows.


    if ['contributor', 'editor', 'super_editor', 'admin'].member? user.role
      can [:edit, :update, :show], :all, :created_by_id => user.id
      can :create, DericciLink

      can :destroy, [Comment, Reply], :created_by_id => user.id
      cannot :manage, Page

      can :link, :all
      can :unlink, :all, :created_by_id => user.id
      can :history, :all

      can [:index, :new], DericciGame
      can :index, [Entry, Source, Manuscript, Comment]

      can :manage, PrivateMessage, :created_by_id => user.id
      can :manage, PrivateMessage do |pm|
        pm.users.include? user
      end
      can :manage, Rating
      cannot [:import, :upload], Entry
    end

    if ['editor', 'super_editor', 'admin'].member? user.role
      can :unlink, :all
      can :edit, Manuscript
      can :manage, DericciRecord

      cannot :deprecate, :all
      can :manage, Name
      cannot :review, Name
      # this needs to be RE-Established, since it has been overriden by line 51
      can :edit, :all, :created_by_id => user.id
      cannot :manage, Page
    end

    if ['super_editor'].member? user.role
      # allow super-editors to edit legacy records
      can [:edit, :update, :verify, :deprecate], Entry, :unverified_legacy_record => true
      can [:edit, :update], Source, :legacy => true
      can :manage, Place
      can :manage, Language
    end

    if ['admin'].member? user.role
      can :manage, :all
      can :update_type, Source
    end

    can [:edit, :update], Entry, contributors: { :id => user.id }
    cannot :manage, [Group]
    can [:edit, :update, :destroy], Group, admin: { :id => user.id }
    can [:destroy], Entry, {created_by_id: user.id, draft: true}

    can :show, Entry
    cannot :show, Entry do |entry|
      (entry.created_by != user && !entry.contributors.include?(user)) && entry.draft
    end
  end
end