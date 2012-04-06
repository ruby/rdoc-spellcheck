# coding: UTF-8

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
  # A list of common words that aspell may not include, but are commonly used
  # in ruby programs.
  #--
  # Please keep this list sorted in your pull requests

  DEFAULT_WORDS = %w[
    API
    ArgumentError
    CGI
    EOFError
    ERb
    Encoding::CompatibilityError
    Encoding::ConverterNotFoundError
    Encoding::InvalidByteSequenceError
    Encoding::UndefinedConversionError
    EncodingError
    Errno::E2BIG
    Errno::EACCES
    Errno::EADDRINUSE
    Errno::EADDRNOTAVAIL
    Errno::EAFNOSUPPORT
    Errno::EAGAIN
    Errno::EALREADY
    Errno::EAUTH
    Errno::EBADF
    Errno::EBADMSG
    Errno::EBADRPC
    Errno::EBUSY
    Errno::ECANCELED
    Errno::ECHILD
    Errno::ECONNABORTED
    Errno::ECONNREFUSED
    Errno::ECONNRESET
    Errno::EDEADLK
    Errno::EDESTADDRREQ
    Errno::EDOM
    Errno::EDQUOT
    Errno::EEXIST
    Errno::EFAULT
    Errno::EFBIG
    Errno::EFTYPE
    Errno::EHOSTDOWN
    Errno::EHOSTUNREACH
    Errno::EIDRM
    Errno::EILSEQ
    Errno::EINPROGRESS
    Errno::EINTR
    Errno::EINVAL
    Errno::EIO
    Errno::EISCONN
    Errno::EISDIR
    Errno::ELOOP
    Errno::EMFILE
    Errno::EMLINK
    Errno::EMSGSIZE
    Errno::EMULTIHOP
    Errno::ENAMETOOLONG
    Errno::ENEEDAUTH
    Errno::ENETDOWN
    Errno::ENETRESET
    Errno::ENETUNREACH
    Errno::ENFILE
    Errno::ENOATTR
    Errno::ENOBUFS
    Errno::ENODATA
    Errno::ENODEV
    Errno::ENOENT
    Errno::ENOEXEC
    Errno::ENOLCK
    Errno::ENOLINK
    Errno::ENOMEM
    Errno::ENOMSG
    Errno::ENOPROTOOPT
    Errno::ENOSPC
    Errno::ENOSR
    Errno::ENOSTR
    Errno::ENOSYS
    Errno::ENOTBLK
    Errno::ENOTCONN
    Errno::ENOTDIR
    Errno::ENOTEMPTY
    Errno::ENOTRECOVERABLE
    Errno::ENOTSOCK
    Errno::ENOTSUP
    Errno::ENOTTY
    Errno::ENXIO
    Errno::EOPNOTSUPP
    Errno::EOVERFLOW
    Errno::EOWNERDEAD
    Errno::EPERM
    Errno::EPFNOSUPPORT
    Errno::EPIPE
    Errno::EPROCLIM
    Errno::EPROCUNAVAIL
    Errno::EPROGMISMATCH
    Errno::EPROGUNAVAIL
    Errno::EPROTO
    Errno::EPROTONOSUPPORT
    Errno::EPROTOTYPE
    Errno::ERANGE
    Errno::EREMOTE
    Errno::EROFS
    Errno::ERPCMISMATCH
    Errno::ESHUTDOWN
    Errno::ESOCKTNOSUPPORT
    Errno::ESPIPE
    Errno::ESRCH
    Errno::ESTALE
    Errno::ETIME
    Errno::ETIMEDOUT
    Errno::ETOOMANYREFS
    Errno::ETXTBSY
    Errno::EUSERS
    Errno::EXDEV
    Errno::NOERROR
    Exception
    FIXME
    FiberError
    FileUtils
    FloatDomainError
    GPL
    IOError
    IndexError
    Interrupt
    KeyError
    LoadError
    LocalJumpError
    Math::DomainError
    NUL
    NameError
    NoMemoryError
    NoMethodError
    NoMethodError
    NotImplementedError
    PHP
    README
    RangeError
    RegexpError
    RuntimeError
    ScriptError
    SecurityError
    SignalException
    StandardError
    StopIteration
    StringIO
    SyntaxError
    SystemCallError
    SystemExit
    SystemStackError
    ThreadError
    TypeError
    URI
    VCS
    XHTML
    ZeroDivisionError
    Zlib
    accessor
    accessors
    argf
    argv
    ary
    baz
    bom
    cfg
    cpp
    crlf
    deprecations
    dev
    dup
    emacs
    env
    erb
    globals
    gsub
    http
    https
    img
    inlining
    instantiation
    irb
    iso
    ivar
    kbd
    klass
    klasses
    lang
    lexing
    lookup
    lossy
    mailto
    mktmpdir
    newb
    perl
    popup
    pwd
    racc
    rbw
    redistributions
    refactor
    refactored
    startup
    stderr
    stdin
    stdout
    struct
    succ
    sudo
    tmpdir
    tokenizer
    tokenizes
    txt
    unescape
    unescapes
    uniq
    unmaintained
    unordered
    untrusted
    utf
    validator
    validators
    visibilities
    www
    yacc
  ]

  ##
  # OptionParser validator for Aspell language dictionaries

  SpellLanguage = Object.new

  attr_reader :spell # :nodoc:

  ##
  # Adds rdoc-spellcheck options to the rdoc command

  def self.setup_options options
    default_language, = ENV['LANG'].split '.'

    options.spell_add_words  = false
    options.spell_language   = default_language
    options.spell_source_dir = Dir.pwd
    options.quiet            = true # suppress statistics

    op = options.option_parser

    op.accept SpellLanguage do |language|
      found = Aspell.list_dicts.find do |dict|
        dict.name == language
      end

      raise OptionParser::InvalidArgument,
            "dictionary #{language} not installed" unless found

      language
    end

    op.separator nil
    op.separator 'Spellcheck options:'
    op.separator nil

    op.on('--spell-add-words [WORDLIST]',
          'Adds words to the aspell personal wordlist.',
          'The word list may be a comma-separated',
          'list of words which must contain multiple',
          'words, a file or empty to read words from',
          'stdin') do |wordlist|
      words = if wordlist.nil? then
                $stdin.read.split
              elsif wordlist =~ /,/ then
                wordlist.split ','
              else
                open wordlist do |io|
                  io.read.split
                end
              end

      options.spell_add_words = words
    end

    op.separator nil

    op.on('--spell-language=LANGUAGE', SpellLanguage,
          'Language to use for spell checking.',
          "The default language is #{default_language}") do |language|
      options.spell_language = language
    end
  end

  def initialize options # :not-new:
    @options = options

    @encoding   = @options.encoding
    @source_dir = @options.spell_source_dir

    @misspellings = Hash.new 0

    @spell = Aspell.new @options.spell_language, nil, nil, @encoding.name
    @spell.suggestion_mode = Aspell::NORMAL
    @spell.set_option 'run-together', 'true'

    if words = @options.spell_add_words then
      words.each do |word|
        @spell.add_to_personal word
      end

      @spell.save_all_word_lists
    end
  end

  ##
  # Adds +name+ to the dictionary, splitting the word on '_' (a character
  # Aspell does not allow)

  def add_name name
    name.scan(/[a-z]+/i) do |part|
      @spell.add_to_session part
    end
  end

  ##
  # Returns a report of misspelled words in +comment+.  The report contains
  # each misspelled word and its offset in the comment's text.

  def find_misspelled comment
    report = []

    comment.text.scan(/\p{L}[\p{L}']+\p{L}/i) do |word|
      offset = $`.length # store

      word = $` if word =~ /'s$/i

      next if @spell.check word

      offset = offset.zero? ? 0 : offset + 1

      report << [word, offset]

      @misspellings[word] += 1
    end

    report
  end

  ##
  # Creates the spelling report

  def generate files
    setup_dictionary

    report = []

    RDoc::TopLevel.all_classes_and_modules.each do |mod|
      mod.comment_location.each do |comment, location|
        report.concat misspellings_for(mod.definition, comment, location)
      end

      mod.each_include do |incl|
        name = "#{incl.parent.full_name}.include #{incl.name}"

        report.concat misspellings_for(name, incl.comment, incl.file)
      end

      mod.each_constant do |const|
        # TODO add missing RDoc::Constant#full_name
        name = const.parent ? const.parent.full_name : '(unknown)'
        name = "#{name}::#{const.name}"

        report.concat misspellings_for(name, const.comment, const.file)
      end

      mod.each_attribute do |attr|
        name = "#{attr.parent.full_name}.#{attr.definition} :#{attr.name}"

        report.concat misspellings_for(name, attr.comment, attr.file)
      end

      mod.each_method do |meth|
        report.concat misspellings_for(meth.full_name, meth.comment, meth.file)
      end
    end

    RDoc::TopLevel.all_files.each do |file|
      report.concat misspellings_for(nil, file.comment, file)
    end

    if @misspellings.empty? then
      puts 'No misspellings found'
    else
      puts report.join "\n"
      puts

      num_width = @misspellings.values.max.to_s.length
      order = @misspellings.sort_by do |word, count|
        [-count, word]
      end

      puts 'Top misspellings:'
      order.first(10).each do |word, count|
        puts "%*d %s" % [num_width, count, word]
      end
    end
  end

  ##
  # Determines the line and column of the misspelling in +comment+ at +offset+
  # in the +file+.

  def location_of text, offset, file
    last_newline = text[0, offset].rindex "\n"
    start_of_line = last_newline ? last_newline + 1 : 0

    line_text = text[start_of_line..offset]

    full_path = File.expand_path file.absolute_name, @source_dir

    file_content = RDoc::Encoding.read_file full_path, @encoding

    raise "[bug] Unable to read #{full_path}" unless file_content

    file_content.each_line.with_index do |line, index|
      if line =~ /#{Regexp.escape line_text}/ then
        column = $`.length + line_text.length
        return index, column
      end
    end

    # TODO typos in include file

    nil
  end

  ##
  # Returns a report of misspellings the +comment+ at +location+ for
  # documentation item +name+

  def misspellings_for name, comment, location
    out = []

    return out if comment.empty?

    misspelled = find_misspelled comment

    return out if misspelled.empty?

    if name then
      out << "#{name} in #{location.full_name}:"
    else
      out << "In #{location.full_name}:"
    end

    out << nil

    out.concat misspelled.flat_map { |word, offset|
      suggestion = suggestion_text comment.text, word, offset
      line, column = location_of word, offset, location

      if line then
        ["#{location.absolute_name}:#{line}:#{column}", suggestion]
      else
        ["(via include)", suggestion]
      end
    }

    out
  end

  ##
  # Adds file names, class names, module names, method names, etc. from the
  # documentation tree to the session spelling dictionary.

  def setup_dictionary
    DEFAULT_WORDS.each do |word|
      add_name word
    end

    RDoc::TopLevel.all_classes_and_modules.each do |mod|
      add_name mod.name

      mod.each_include do |incl|
        add_name incl.name
      end

      mod.each_constant do |const|
        add_name const.name
      end

      mod.each_attribute do |attr|
        add_name attr.name
      end

      mod.each_method do |meth|
        add_name meth.name
        add_name meth.params       if meth.params
        add_name meth.block_params if meth.block_params
      end
    end

    RDoc::TopLevel.all_files.each do |file|
      file.absolute_name.split(%r%[/\\.]%).each do |part|
        add_name part
      end
    end
  end

  ##
  # Creates suggestion text for the misspelled +word+ at +offset+ in +text+

  def suggestion_text text, word, offset
    prefix = offset - 10
    prefix = 0 if prefix < 0

    text =~ /\A.{#{prefix}}(.{0,10})#{Regexp.escape word}(.{0,10})/m

    before    = "#{prefix.zero? ? nil : '...'}#{$1}"
    after     = "#{$2}#{$2.length < 10 ? nil : '...'}"

    highlight = "\e[1;31m#{word}\e[m"

    suggestions = @spell.suggest(word).first 5

    <<-TEXT
"#{before}#{highlight}#{after}"

"#{word}" suggestions:
\t#{suggestions.join ', '}

    TEXT
  rescue => e
    $stderr.puts "[bug] #{e.class}: #{e.message}"
    $stderr.puts
    $stderr.puts "word:   #{word}"
    $stderr.puts "offset: #{offset}"
    $stderr.puts ">>>> start text <<<<\n#{text}\n>>>>> end text <<<<<"
    raise
  end

end

class RDoc::Options

  ##
  # Enables addition of words to the personal wordlist

  attr_accessor :spell_add_words

  ##
  # The Aspell dictionary language to use.  Defaults to the language in the
  # LANG environment variable.

  attr_accessor :spell_language

  ##
  # The directory spellcheck was run from which contains all the source files.

  attr_accessor :spell_source_dir

end

