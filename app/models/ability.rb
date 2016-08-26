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

    if ['contributor', 'editor', 'admin'].member? user.role
      can [:edit, :update], :all, :created_by_id => user.id
      can :link, :all
      can :index, Entry

      can :history, :all

      can :unlink, :all, :created_by_id => user.id
      can :manage, PrivateMessage, :created_by_id => user.id
      can :manage, PrivateMessage, :user_id => user.id
    end

    if ['editor', 'admin'].member? user.role
      can :manage, [Name, Entry, Manuscript, Source]
      can :unlink, :all
      can :edit, Manuscript

      cannot :deprecate, :all
      cannot [:edit, :destroy, :merge], [Source, Entry]
      can :edit, :all, :created_by_id => user.id

      # allow editors to edit legacy records
      can :edit, Entry, :unverified_legacy_record => true   
    end

    if ['admin'].member? user.role
      can :manage, :all
      #can :destroy, :all
    end

=begin
    if ['contributor', 'editor', 'admin'].member? user.role
      can :show, :all
      [Entry, Sale, Language, Manuscript, Name, Place, Source, Comment].each do |clazz|
        can :create, clazz
        can :new, clazz
        can :edit, clazz, :created_by_id => user.id
        can :update, clazz, :created_by_id => user.id
        # TODO: should users be able to delete their own records?
        can :destroy, clazz, :created_by_id => user.id
        cannot :merge, clazz
      end
      can :link, Entry
      can :link, Manuscript
      can :index, Entry

      can :history, :all
      # Decided by Lynn on 6/9/2015: A contributor can edit ANY
      # manuscript. The thinking here is that a Manuscript isn't
      # "owned" by the user in the same way as an Entry.
      
      can :unlink, Manuscript, :created_by_id => user.id
      can :unlink, Entry, :created_by_id => user.id
    end

    if ['editor', 'admin'].member? user.role
      [Entry, Sale, Language, Manuscript, Name, Place].each do |clazz|
        can :merge, clazz
      end
      [Entry, Source, Manuscript, Name].each do |clazz|
        can :manage, clazz
      end
      [Manuscript, Name].each do |clazz|
        can :destroy, clazz
      end

      can :edit, Manuscript
      can :unlink, Manuscript
      can :unlink, Entry
    end

    if ['editor'].member? user.role
      can :manage, EntryManuscript
      [Entry, Source].each do |clazz|
        cannot :destroy, clazz
        cannot :deprecate, clazz
        cannot :edit, clazz
        cannot :merge, clazz
      end
    end

    if ['admin'].member? user.role
      can :manage, :all
      can :destroy, :all
    end
=end

  end
end