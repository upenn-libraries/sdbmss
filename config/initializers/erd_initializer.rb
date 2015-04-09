
# Patch from https://github.com/voormedia/rails-erd/issues/70
# to solve "Error: in routesplines, cannot find NORMAL edge" msg
# from graphviz.

begin
  require 'rails_erd/domain/relationship'

  module RailsERD
    class Domain
      class Relationship
        class << self
          private

          def association_identity(association)
            Set[association_owner(association), association_target(association)]
          end
        end
      end
    end
  end
rescue LoadError => e
  # just ignore if rails-erd gem isn't in Gemfile
end
