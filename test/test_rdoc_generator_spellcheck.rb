require 'rubygems'
require 'minitest/autorun'

require 'rdoc/generator/spellcheck'
require 'rdoc/test_case'

class TestRDocGeneratorSpellcheck < RDoc::TestCase

  def setup
    super

    @top_level = RDoc::TopLevel.new 'file.rb'

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

  def test_find_misspelled
    c = comment 'Hello, this class has real gud spelling!'

    report = @sc.find_misspelled c

    word, offset = report.shift

    assert_equal 'gud', word
    assert_equal 28,    offset
  end

  def test_generate
    klass = @top_level.add_class RDoc::NormalClass, 'Object'

    c = comment 'Hello, this class has real gud spelling!'
    klass.add_comment c, @top_level

    out, err = capture_io do
      @sc.generate [@top_level]
    end

    assert_empty err

    suggestions = suggest('gud').join ', '

    expected = <<-EXPECTED
class Object in file.rb:

"...has real _\bg_\bu_\bd spelling!..."

"gud" suggestions:
\t#{suggestions}

    EXPECTED

    assert_equal expected, out
  end

  def suggest word
    Aspell.new('en_US').suggest(word).first 5
  end

end

