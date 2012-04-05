require 'rubygems'

gem 'rdoc', '~> 3.12'

require 'rdoc'
require 'rdoc/generator'

require 'raspell'

##
# A spell checking generator for RDoc.
#
# This generator creates a report of misspelled words.  You can use it to find
# when you acidentally make a typo.  For example, this line contains one.

class RDoc::Generator::Spellcheck

  RDoc::RDoc.add_generator self

  ##
  # This version of rdoc-spellcheck

  VERSION = '1.0'

  ##
  # OptionParser validator for Aspell language dictionaries

  SpellLanguage = Object.new

  ##
  # Adds rdoc-spellcheck options to the rdoc command

  def self.setup_options options
    default_language, = ENV['LANG'].split '.'

    options.spell_language = default_language

    op = options.option_parser

    op.accept SpellLanguage do |language|
      found = Aspell.list_dicts.find do |dict|
        dict.name == language
      end

      raise OptionParser::InvalidArgument,
            "dictionary #{language} not installed" unless found

      language
    end

    op.on('--spell-language=LANGUAGE', SpellLanguage,
          'Language to use for spell checking',
          "The default language is #{default_language}") do |language|
      options.spell_language = language
    end
  end

  def initialize options # :not-new:
    @options = options

    @misspellings = 0
    @spell        = Aspell.new @options.spell_language
  end

  ##
  # Returns a report of misspelled words in +comment+.  The report contains
  # each misspelled word and its offset in the comment's text.

  def find_misspelled comment
    report = []

    comment.text.scan(/[a-z_]+/i) do |word|
      next if @spell.check word

      report << [word, $`.length + 1]
    end

    report
  end

  ##
  # Creates the spelling report

  def generate files
    report = []

    RDoc::TopLevel.all_classes_and_modules.each do |mod|
      mod.comment_location.each do |comment, location|
        report.concat misspellings_for(mod.definition, comment, location)
      end
    end

    if @misspellings.zero? then
      puts 'No misspellings found'
    else
      puts report.join "\n"
    end

  end

  def misspellings_for name, comment, location
    out = []

    misspelled = find_misspelled comment

    return out if misspelled.empty?

    @misspellings += misspelled.length

    out << "#{name} in #{location.full_name}:"
    out << nil
    out.concat misspelled.map { |word, offset|
      suggestion_text comment.text, word, offset
    }

    out
  end

  def suggestion_text text, word, offset
    prefix = offset - 10
    prefix = 0 if prefix < 0

    text =~ /\A.{#{prefix}}(.{0,10})#{Regexp.escape word}(.{0,10})/

    before    = "#{prefix.zero? ? nil : '...'}#{$1}"
    after     = "#{$2}#{$2.empty? ? nil : '...'}"
    underline = word.chars.map { |char| "_\b#{char}" }.join
    suggestions = @spell.suggest(word).first 5

    <<-TEXT
"#{before}#{underline}#{after}"

"#{word}" suggestions:
\t#{suggestions.join ', '}

    TEXT
  end

end

class RDoc::Options

  ##
  # The Aspell dictionary language to use.  Defaults to the language in the
  # LANG environment variable.

  attr_accessor :spell_language

end

