def prepare_constants(conf)
  treated_constants = {}
  conf[:constants].each do |k, v|
    treated_constants[k] = v
    treated_constants[k.capitalize] = v unless /[[:upper:]]/ =~ k
  end

  constants = Regexp.new(
    treated_constants.keys.join('|')
  )

  [constants, treated_constants]
end

def get_target_file_name(conf, file)
  source_path = File.expand_path(file)
  source_path.sub conf[:source_dir], conf[:target_dir]
end

def constantize_phrases(conf, constants, treated_constants, original_phrases)
  phrases = []
  original_phrases.each do |phrase|
    encoded = phrase[0].force_encoding(
      conf[:file_encoding]
    ).encode('UTF-8', invalid: :replace, undef: :replace, replace: ' ')
    phrases << encoded.gsub(constants, treated_constants)
  end
end

def get_phrases(conf, constants, file, treated_constants)
  original_phrases = File.read(file, encoding: conf[:file_encoding]).scan(
    conf[:text_chunks_pattern]
  )
  phrases = constantize_phrases(
    conf,
    constants,
    treated_constants,
    original_phrases
  )
  [original_phrases, phrases]
end

def prepare_target_file(file, target_file)
  FileUtils.mkdir_p(File.dirname(target_file))
  FileUtils.cp(file, target_file)
end

def append_translations(raw_translations, tmp)
  if tmp.is_a?(Array)
    raw_translations.concat tmp
  else
    raw_translations << tmp
  end
end

def translate_phrases(conf, phrases, translator)
  raw_translations = []
  until phrases.empty?
    tmp = translator.translate(
      phrases.slice!(0..29),
      from: conf[:source_language],
      to: conf[:target_language],
      format: :text
    )
    append_translations(raw_translations, tmp)
  end
end