
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "qyu/version"

Gem::Specification.new do |spec|
  spec.name                  = "qyu"
  spec.version               = Qyu::VERSION
  spec.authors               = ['Elod Peter', 'Mohamed Osama']
  spec.email                 = ['bejmuller@gmail.com', 'mohamed.o.alnagdy@gmail.com']
  spec.license               = "MIT"

  spec.summary               = 'Distributed task execution system for complex workflows'
  spec.description           = 'Qyu makes use of a message queue and a state store to provide a reliable distributed task execution system for complex workflows'
  spec.homepage              = 'https://github.com/QyuTeam/qyu'
  spec.required_ruby_version = '>= 2.4'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|examples)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.metadata["yard.run"] = "yri"

  spec.add_runtime_dependency 'activesupport', '~> 5.1'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'dotenv', '~> 2.0'
  spec.add_development_dependency 'rack-test', '~> 1.0'
  spec.add_development_dependency 'pry', '~> 0.11'
  spec.add_development_dependency 'pry-byebug', '~> 3.0'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'codecov', '~> 0.1'
  spec.add_development_dependency 'sinatra', '~> 2.0'
  spec.add_development_dependency 'timecop', '~> 0.9'
end
