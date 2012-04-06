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

    @text = 'Hello, this class has real gud spelling!'
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
    c = comment @text

    report = @sc.find_misspelled c

    word, offset = report.shift

    assert_equal 'gud', word
    assert_equal 28,    offset
  end

  def test_generate
    klass = @top_level.add_class RDoc::NormalClass, 'Object'

    c = comment @text
    klass.add_comment c, @top_level

    out, err = capture_io do
      @sc.generate [@top_level]
    end

    assert_empty err

    assert_match %r%^class Object in file\.rb:%, out
    assert_match %r%^"gud"%,                     out
  end

  def test_generate_correct
    klass = @top_level.add_class RDoc::NormalClass, 'Object'

    c = comment 'This class has perfect spelling!'
    klass.add_comment c, @top_level

    out, err = capture_io do
      @sc.generate [@top_level]
    end

    assert_empty err
    assert_equal "No misspellings found\n", out
  end

  def test_generate_method
    klass = @top_level.add_class RDoc::NormalClass, 'Object'

    meth = RDoc::AnyMethod.new nil, 'method'
    meth.record_location @top_level
    meth.comment = comment @text, meth

    klass.add_method meth

    out, err = capture_io do
      @sc.generate [@top_level]
    end

    assert_empty err

    assert_match %r%^Object#method in file\.rb:%, out
    assert_match %r%^"gud"%,                      out
  end

  def test_misspellings_for
    out = @sc.misspellings_for 'class Object', comment(@text), @top_level

    out = out.join "\n"

    assert_match %r%^class Object in file\.rb:%, out
    assert_match %r%^"gud"%,                     out
  end

  def test_misspellings_for_empty
    out = @sc.misspellings_for 'class Object', comment(''), @top_level

    assert_empty out
  end

  def test_suggestion_text
    out = @sc.suggestion_text @text, 'gud', 28

    suggestions = suggest('gud').join ', '

    expected = <<-EXPECTED
"...has real _\bg_\bu_\bd spelling!..."

"gud" suggestions:
\t#{suggestions}

    EXPECTED

    assert_equal expected, out
  end

  def test_suggestion_text_start
    out = @sc.suggestion_text 'gud night world, see you tomorrow', 'gud', 0

    suggestions = suggest('gud').join ', '

    expected = <<-EXPECTED
"_\bg_\bu_\bd night wor..."

"gud" suggestions:
\t#{suggestions}

    EXPECTED

    assert_equal expected, out
  end

  def test_suggestion_text_end
    out = @sc.suggestion_text 'you did real gud', 'gud', 14

    suggestions = suggest('gud').join ', '

    expected = <<-EXPECTED
"...did real _\bg_\bu_\bd"

"gud" suggestions:
\t#{suggestions}

    EXPECTED

    assert_equal expected, out
  end

  def suggest word
    Aspell.new('en_US').suggest(word).first 5
  end

end

