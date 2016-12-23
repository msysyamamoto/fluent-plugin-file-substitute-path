# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-parameterized-path"
  spec.version       = "0.1.1"
  spec.authors       = ["Masayasu Yamamoto"]
  spec.email         = ["m2yamamoto@gmail.com"]

  spec.summary       = %q{Apply the value of the specified field to part of the path.}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/msysyamamoto/fluent-plugin-parameterized-path"
  spec.license       = "Apache License 2.0"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "fluentd", ">= 0.14.0"
  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "test-unit"

  spec.required_ruby_version = ">= 2.1.0"
end
