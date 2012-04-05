require 'rubygems'
require 'minitest/autorun'

require 'rdoc/generator/spellcheck'
require 'rdoc/test_case'

class TestRDocGeneratorSpellcheck < RDoc::TestCase

  def setup
    super

    @SC = RDoc::Generator::Spellcheck
    @options = RDoc::Options.new
    @options.spell_language = 'en_US'

    @sc = @SC.new @options
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

  def test_generate
    tl = RDoc::TopLevel.new 'file.rb'
    klass = tl.add_class RDoc::NormalClass, 'Object'

    comment = RDoc::Comment.new 'Hello, this class has real gud spelling!', tl
    klass.add_comment comment, tl

    out, err = capture_io do
      @sc.generate [tl]
    end

    assert_empty err
    assert_equal "gud\n", out
  end

end

