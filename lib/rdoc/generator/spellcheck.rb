require 'rubygems'

gem 'rdoc', '~> 3.12'

require 'rdoc'
require 'rdoc/generator'

require 'raspell'

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

end

class RDoc::Options

  ##
  # The Aspell dictionary language to use.  Defaults to the language in the
  # LANG environment variable.

  attr_accessor :spell_language

end

