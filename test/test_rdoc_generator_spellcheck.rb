# coding: UTF-8

require 'rubygems'
require 'minitest/autorun'
require 'stringio'
require 'tempfile'

gem 'rdoc', '~> 3.12'

require 'rdoc' # automatically requires rdoc/generator/spell_check
require 'rdoc/test_case'

class TestRDocGeneratorSpellcheck < RDoc::TestCase

  def setup
    super

    @SC = RDoc::Generator::Spellcheck
    @options = RDoc::Options.new
    @options.spell_language = 'en_US'

    @sc = @SC.new @options

    @text = 'Hello, this class has real gud spelling!'

    @tempfile = Tempfile.new __name__
    @tempfile.puts "# #{@text}"
    @tempfile.puts
    @tempfile.puts "# funkify thingus"
    @tempfile.flush

    @escaped_path = Regexp.escape @tempfile.path

    @top_level = RDoc::TopLevel.new @tempfile.path
    @top_level.comment = comment 'funkify_thingus'

    method = RDoc::AnyMethod.new nil, 'funkify_thingus'
    @top_level.add_method method
  end

  def teardown
    @tempfile.close

    super
  end

  def test_add_name
    @sc.add_name 'funkify_thingus'

    assert @sc.spell.check('funkify'), 'funkify not added to wordlist'
    assert @sc.spell.check('thingus'), 'thingus not added to wordlist'
  end

  def test_class_setup_options_default
    orig_lang = ENV['LANG']
    ENV['LANG'] = 'en_US.UTF-8'

    options = RDoc::Options.new

    options.parse %w[--format spellcheck]

    refute                options.spell_add_words
    assert_equal 'en_US', options.spell_language
    assert_equal Dir.pwd, options.spell_source_dir
    assert                options.quiet
  ensure
    ENV['LANG'] = orig_lang
  end

  def test_class_setup_options_spell_add_words
    $stdin = StringIO.new "foo bar\nbaz"

    options = RDoc::Options.new

    options.parse %w[
      --format spellcheck
      --no-ignore-invalid
      --spell-add-words
    ]

    assert_equal %w[foo bar baz], options.spell_add_words
  ensure
    $stdin = STDIN
  end

  def test_class_setup_options_spell_add_words_list
    options = RDoc::Options.new

    options.parse %w[
      --format spellcheck
      --no-ignore-invalid
      --spell-add-words foo,bar
    ]

    assert_equal %w[foo bar], options.spell_add_words
  end

  def test_class_setup_options_spell_add_words_file
    Tempfile.open 'words.txt' do |io|
      io.write "foo bar\nbaz"
      io.rewind

      options = RDoc::Options.new

      options.parse %W[
        --format spellcheck
        --no-ignore-invalid
        --spell-add-words #{io.path}
      ]

      assert_equal %w[foo bar baz], options.spell_add_words
    end
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

  def test_initialize_add_words
    private_wordlist do
      @options.spell_add_words = %w[funkify thingus]

      sc = @SC.new @options

      spell = Aspell.new 'en_US'

      assert spell.check('funkify'), 'funkify not added to personal wordlist'
      assert spell.check('thingus'), 'thingus not added to personal wordlist'
    end
  end

  def test_add_name
    @sc.add_name '<=>'

    assert true # just for counting
  end

  def test_add_name_utf_8
    @sc.add_name 'Володя'

    assert true # just for counting
  end

  def test_find_misspelled
    private_wordlist do
      c = comment @text

      report = @sc.find_misspelled c

      word, offset = report.shift

      assert_equal 'gud', word
      assert_equal 28,    offset
    end
  end

  def test_find_misspelled_quote
    c = comment "doesn't"

    report = @sc.find_misspelled c

    assert_empty report

    c = comment "'quoted'"

    report = @sc.find_misspelled c

    assert_empty report

    c = comment "other's"

    report = @sc.find_misspelled c

    assert_empty report
  end

  def test_find_misspelled_underscore
    private_wordlist do
      c = comment 'gud_method'

      report = @sc.find_misspelled c

      word, offset = report.shift

      assert_equal 'gud', word
      assert_equal 0,    offset
    end
  end

  def test_find_misspelled_utf_8
    private_wordlist do
      c = comment 'Marvin Gülker'

      report = @sc.find_misspelled c

      assert_empty report
    end
  end

  def test_generate_alias
    klass = @top_level.add_class RDoc::NormalClass, 'Object'

    meth = RDoc::AnyMethod.new nil, 'new'
    meth.comment = comment ''
    meth.record_location @top_level

    klass.add_method meth
    alas = RDoc::Alias.new nil, 'old', 'new', comment(@text)
    alas.record_location @top_level

    klass.add_alias alas

    out, err = capture_io do
      @sc.generate [@top_level]
    end

    assert_empty err

    assert_match %r%^Object alias old new in #{@escaped_path}:%, out
    assert_match %r%^"gud"%,                                     out
  end

  def test_generate_attribute
    klass = @top_level.add_class RDoc::NormalClass, 'Object'

    attribute = RDoc::Attr.new nil, 'attr', 'RW', comment(@text)
    attribute.record_location @top_level

    klass.add_attribute attribute

    out, err = capture_io do
      @sc.generate [@top_level]
    end

    assert_empty err

    assert_match %r%^Object\.attr_accessor :attr in #{@escaped_path}:%, out
    assert_match %r%^"gud"%,                                            out
  end

  def test_generate_class
    klass = @top_level.add_class RDoc::NormalClass, 'Object'

    c = comment @text
    klass.add_comment c, @top_level

    out, err = capture_io do
      @sc.generate [@top_level]
    end

    assert_empty err

    assert_match %r%^class Object in #{@escaped_path}:%, out
    assert_match %r%^"gud"%,                             out
  end

  def test_generate_constant
    klass = @top_level.add_class RDoc::NormalClass, 'Object'

    const = RDoc::Constant.new 'CONSTANT', nil, comment(@text)
    const.record_location @top_level

    klass.add_constant const

    out, err = capture_io do
      @sc.generate [@top_level]
    end

    assert_empty err

    assert_match %r%^Object::CONSTANT in #{@escaped_path}:%, out
    assert_match %r%^"gud"%,                                 out
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

  def test_generate_file
    @top_level.comment = comment @text
    @top_level.parser = RDoc::Parser::Text

    out, err = capture_io do
      @sc.generate [@top_level]
    end

    assert_empty err

    assert_match %r%^In #{@escaped_path}:%, out
    assert_match %r%^"gud"%,                out
  end

  def test_generate_include
    klass = @top_level.add_class RDoc::NormalClass, 'Object'

    incl = RDoc::Include.new 'INCLUDE', comment(@text)
    incl.record_location @top_level

    klass.add_include incl

    out, err = capture_io do
      @sc.generate [@top_level]
    end

    assert_empty err

    assert_match %r%^Object\.include INCLUDE in #{@escaped_path}:%, out
    assert_match %r%^"gud"%,                                        out
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

    assert_match %r%^Object#method in #{@escaped_path}:%, out
    assert_match %r%^"gud"%,                              out
  end

  def test_generate_multiple
    klass = @top_level.add_class RDoc::NormalClass, 'Object'
    c = comment @text
    klass.add_comment c, @top_level

    meth = RDoc::AnyMethod.new nil, 'method'
    meth.record_location @top_level
    meth.comment = comment @text, meth

    klass.add_method meth

    out, err = capture_io do
      @sc.generate [@top_level]
    end

    assert_empty err

    assert_match %r%^Object#method in #{@escaped_path}:%, out
    assert_match %r%^"gud"%,                              out
    assert_match %r%^2 gud%,                              out
  end

  def test_location_of
    Tempfile.open 'location_of' do |io|
      io.puts "##"
      io.puts "# Here is some text with proper spelling"
      io.puts "#"
      io.puts "# #{@text}"
      io.flush

      tl = RDoc::TopLevel.new io.path
      text = "Here is some text with proper spelling\n\n#{@text}"
      offset = text.index "gud"

      line, column = @sc.location_of text, offset, tl

      assert_equal 3,  line
      assert_equal 30, column
    end
  end

  def test_location_of_first_line
    Tempfile.open 'location_of' do |io|
      io.puts "# #{@text}"
      io.flush

      tl = RDoc::TopLevel.new io.path
      offset = @text.index "gud"

      line, column = @sc.location_of @text, offset, tl

      assert_equal 0,  line
      assert_equal 30, column
    end
  end

  def test_misspellings_for
    out = @sc.misspellings_for 'class Object', comment(@text), @top_level

    out = out.join "\n"

    location = Regexp.escape @top_level.absolute_name
    assert_match %r%^class Object in #{location}%, out
    assert_match %r%^#{location}:0:32%,            out
    assert_match %r%^"gud"%,                       out
  end

  def test_misspellings_for_empty
    out = @sc.misspellings_for 'class Object', comment(''), @top_level

    assert_empty out
  end

  def test_setup_dictionary_alias
    klass = @top_level.add_class RDoc::NormalClass, 'Object'

    meth = RDoc::AnyMethod.new nil, 'new'
    meth.comment = comment ''
    meth.record_location @top_level

    klass.add_method meth
    alas = RDoc::Alias.new nil, 'funkify_thingus', 'new', comment(@text)
    alas.record_location @top_level

    klass.add_alias alas

    @sc.setup_dictionary

    assert @sc.spell.check('funkify'), 'funkify not added to wordlist'
    assert @sc.spell.check('thingus'), 'thingus not added to wordlist'
  end

  def test_setup_dictionary_attribute
    klass = @top_level.add_class RDoc::NormalClass, 'Object'

    attribute = RDoc::Attr.new nil, 'funkify_thingus', 'RW', comment(@text)
    attribute.record_location @top_level

    klass.add_attribute attribute

    @sc.setup_dictionary

    assert @sc.spell.check('FUNKIFY'), 'FUNKIFY not added to wordlist'
    assert @sc.spell.check('THINGUS'), 'THINGUS not added to wordlist'
  end

  def test_setup_dictionary_class
    klass = @top_level.add_class RDoc::NormalClass, 'FunkifyThingus'

    c = comment @text
    klass.add_comment c, @top_level

    @sc.setup_dictionary

    assert @sc.spell.check('FunkifyThingus'),
           'FunkifyThingus not added to wordlist'
  end

  def test_setup_dictionary_constant
    klass = @top_level.add_class RDoc::NormalClass, 'Object'

    const = RDoc::Constant.new 'FUNKIFY_THINGUS', nil, comment(@text)
    const.record_location @top_level

    klass.add_constant const

    @sc.setup_dictionary

    assert @sc.spell.check('FUNKIFY'), 'FUNKIFY not added to wordlist'
    assert @sc.spell.check('THINGUS'), 'THINGUS not added to wordlist'
  end

  def test_setup_dictionary_defaults
    @sc.setup_dictionary

    word = RDoc::Generator::Spellcheck::DEFAULT_WORDS.first

    assert @sc.spell.check(word), "#{word} not added to wordlist"
  end

  def test_setup_dictionary_file
    RDoc::TopLevel.new 'funkify_thingus.rb'

    @sc.setup_dictionary

    assert @sc.spell.check('funkify'), 'funkify not added to wordlist'
    assert @sc.spell.check('thingus'), 'thingus not added to wordlist'
  end

  def test_setup_dictionary_include
    klass = @top_level.add_class RDoc::NormalClass, 'Object'

    incl = RDoc::Include.new 'FUNKIFY_THINGUS', comment(@text)
    incl.record_location @top_level

    klass.add_include incl

    @sc.setup_dictionary

    assert @sc.spell.check('FUNKIFY'), 'FUNKIFY not added to wordlist'
    assert @sc.spell.check('THINGUS'), 'THINGUS not added to wordlist'
  end

  def test_setup_dictionary_method
    klass = @top_level.add_class RDoc::NormalClass, 'Object'

    meth = RDoc::AnyMethod.new nil, 'bagas_methd'
    meth.block_params = 'foo, bar'
    meth.params       = 'baz, hoge'
    meth.record_location @top_level
    meth.comment = comment @text, meth

    klass.add_method meth

    @sc.setup_dictionary

    assert @sc.spell.check('bagas'),  'bagas not added to wordlist'
    assert @sc.spell.check('methd'),  'methd not added to wordlist'

    assert @sc.spell.check('foo'),    'foo not added to wordlist'
    assert @sc.spell.check('bar'),    'bar not added to wordlist'
    assert @sc.spell.check('baz'),    'baz not added to wordlist'
    assert @sc.spell.check('hoge'),   'hoge not added to wordlist'
  end

  def test_suggestion_text
    out = @sc.suggestion_text @text, 'gud', 28

    suggestions = suggest('gud').join ', '

    expected = <<-EXPECTED
"...has real \e[1;31mgud\e[m spelling!..."

"gud" suggestions:
\t#{suggestions}

    EXPECTED

    assert_equal expected, out
  end

  def test_suggestion_text_end
    out = @sc.suggestion_text 'you did real gud', 'gud', 14

    suggestions = suggest('gud').join ', '

    expected = <<-EXPECTED
"...did real \e[1;31mgud\e[m"

"gud" suggestions:
\t#{suggestions}

    EXPECTED

    assert_equal expected, out
  end

  def test_suggestion_text_newline
    text = "This text has a typo\non the secnd line"
    out = @sc.suggestion_text text, 'secnd', 29

    suggestions = suggest('secnd').join ', '

    expected = <<-EXPECTED
"...o\non the \e[1;31msecnd\e[m line"

"secnd" suggestions:
\t#{suggestions}

    EXPECTED

    assert_equal expected, out
  end

  def test_suggestion_text_start
    out = @sc.suggestion_text 'gud night world, see you tomorrow', 'gud', 0

    suggestions = suggest('gud').join ', '

    expected = <<-EXPECTED
"\e[1;31mgud\e[m night wor..."

"gud" suggestions:
\t#{suggestions}

    EXPECTED

    assert_equal expected, out
  end

  def private_wordlist
    orig_aspell_conf = ENV['ASPELL_CONF']

    Tempfile.open 'personal_wordlist' do |wordlist|
      Tempfile.open 'personal_repl' do |repl|
        ENV['ASPELL_CONF'] = "personal #{wordlist.path};repl #{repl.path}"

        yield
      end
    end
  ensure
    ENV['ASPELL_CONF'] = orig_aspell_conf
  end

  def suggest word
    Aspell.new('en_US').suggest(word).first 5
  end

end

