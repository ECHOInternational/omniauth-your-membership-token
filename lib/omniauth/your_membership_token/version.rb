module OmniAuth
  module YourMembershipToken
    def self.gem_version
      Gem::Version.new('2.0.0')
    end

    # @deprecated But will never be removed. Use `gem_version` instead, which
    # provides a `Gem::Version` object that is easier to work with.
    VERSION = gem_version.to_s
  end
end
