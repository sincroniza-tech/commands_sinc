# frozen_string_literal: true

require_relative "lib/commands_sinc/version"

Gem::Specification.new do |spec|
  spec.name = "commands_sinc"
  spec.version = CommandsSinc::VERSION
  spec.authors = ["Matheus Lopes"]
  spec.email = ["matheus.lopes@cldl.com.br"]

  spec.summary = "TODO: Write a short summary, because RubyGems requires one."
  spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = "https://github.com/sincroniza-tech/commands_sinc"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'roo'
  spec.add_dependency 'json'
  spec.add_dependency 'httparty'
  spec.add_dependency 'pry'
  spec.add_dependency 'concurrent-ruby'
  spec.add_dependency 'write_xlsx'
  spec.add_dependency 'parallel'
  spec.add_dependency 'benchmark'

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
