# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spoon/version'

Gem::Specification.new do |spec|
  spec.name          = "spoon"
  spec.version       = Spoon::VERSION
  spec.authors       = ["Tomas Slusny"]
  spec.email         = ["slusnucky@gmail.com"]

  spec.summary       = %q{Programming language that runs blazingly fast, compiles to native code and works everywhere}
  spec.description   = %q{Spoon is awesome new programming language, what combines the best things from Ruby and Python. Spoon is open source, cross-platform and runs on top of Haxe.}
  spec.homepage      = "https://spoonlang.org"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ast"
  spec.add_dependency "colorize"
  spec.add_dependency "parslet"
  spec.add_dependency "thor"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "yard"
end
