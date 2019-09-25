# frozen_string_literal: true

module Facter
  module Debian
    class OsLsbRelease
      FACT_NAME = 'os.distro'

      def call_the_resolver
        distro = {
          'codename' => resolve_lsb(:codename),
          'description' => resolve_lsb(:description),
          'id' => resolve_lsb(:distributor_id),
          'release' => {
            'full' => resolve_version(:full),
            'major' => resolve_version(:major),
            'minor' => resolve_version(:minor)
          }
        }

        ResolvedFact.new(FACT_NAME, distro)
      end

      def resolve_lsb(key)
        Resolvers::LsbRelease.resolve(key)
      end

      def resolve_version(key)
        Resolvers::DebianVersion.resolve(key)
      end
    end
  end
end
