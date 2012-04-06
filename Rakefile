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

  dependency 'raspell', '~> 1.3'
  dependency 'rdoc',    '~> 3.12'
end

# vim: syntax=ruby
