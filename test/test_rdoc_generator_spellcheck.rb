require 'rubygems'
require 'minitest/autorun'

require 'rdoc/generator/spellcheck'
require 'rdoc/test_case'

class TestRDocGeneratorSpellcheck < RDoc::TestCase

  def setup
    super

    @S = RDoc::Generator::Spellcheck
  end

  def test_class_setup_options_default
    orig_lang = ENV['LANG']
    ENV['LANG'] = 'en_US.UTF-8'

    options = RDoc::Options.new

    options.parse %w[--format spellcheck]

    assert_equal 'en_US', options.spell_language
  end

  def test_class_setup_options_spell_language
    options = RDoc::Options.new

    options.parse %w[
      --format spellcheck
      --no-ignore-invalid
      --spell-language en_GB
    ]

    assert_equal 'en_GB', options.spell_language
  end

end

