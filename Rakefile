# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.plugin :minitest
Hoe.plugin :git
Hoe.plugin :travis

Hoe.spec 'rdoc-spellcheck' do
  developer 'Eric Hodel', 'drbrain@segment7.net'

  rdoc_locations <<
    'docs.seattlerb.org:/data/www/docs.seattlerb.org/rdoc-spellcheck/'

  # Too lazy to make Unicode Regexps work on Ruby 1.8 and 1.9
  spec_extras['required_ruby_version'] = '>= 1.9.2'

  dependency 'raspell', '~> 1.3'
  dependency 'rdoc',    '~> 3.12'
end

# vim: syntax=ruby
