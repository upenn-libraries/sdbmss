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

    # TODO: fill this out

    if ['contributor', 'editor', 'admin'].member? user.role
      can :create, Entry
      can :new, Entry
      can :edit, Entry, :created_by_id => user.id
      can :update, Entry, :created_by_id => user.id
    end

    if ['editor', 'admin'].member? user.role
      can :edit, Entry
    end

    if ['admin'].member? user.role
      can :manage, :all
    end

  end
end