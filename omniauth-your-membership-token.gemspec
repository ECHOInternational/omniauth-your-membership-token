# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'omniauth/your_membership_token/version'

Gem::Specification.new do |spec|
  spec.name          = "omniauth-your-membership-token"
  spec.version       = OmniAuth::YourMembershipToken::VERSION
  spec.authors       = ["Nate Flood"]
  spec.email         = ["nflood@echonet.org"]
  spec.summary       = %q{Omniauth Strategy For Authenticating To YourMembership}
  spec.description   = %q{This is an Omniauth Strategy for Authenticating to YourMembership. It requires the your_membership gem.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "omniauth", "~> 1.2"
  spec.add_dependency "your_membership", "~> 1.1"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
