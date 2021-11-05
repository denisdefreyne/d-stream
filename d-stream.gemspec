# frozen_string_literal: true

require_relative 'lib/d-stream/version'

Gem::Specification.new do |s|
  s.name        = 'd-stream'
  s.version     = DStream::VERSION
  s.homepage    = 'http://rubygems.org/gems/d-stream'
  s.summary     = 'lazy streaming utils'
  s.description = 'D★Stream is a set of utilities for dealing with lazy streams.'

  s.author  = 'Denis Defreyne'
  s.email   = 'denis.defreyne@stoneship.org'
  s.license = 'MIT'

  s.files =
    Dir['[A-Z]*'] +
    Dir['{lib,spec}/**/*'] +
    ['d-stream.gemspec']
  s.require_paths = ['lib']

  s.rdoc_options     = ['--main', 'README.md']
  s.extra_rdoc_files = ['LICENSE', 'README.md', 'NEWS.md']

  s.required_ruby_version = '~> 3.0'

  s.add_runtime_dependency('ddbuffer', '>= 0.1', '< 2.0')
  s.add_development_dependency('bundler', '~> 1.14')
end
