require 'fileutils'
require 'yaml'
require 'google/cloud/translate'
require 'utilities.rb'

conf = YAML.load_file(ARGV[0].nil? ? 'translator.yml' : ARGV[0])

# TODO: validate confs

translator = Google::Cloud::Translate.new(
  key: conf[:google_translate_api_key],
  retries: 10,
  timeout: 120
)

constants, treated_constants = prepare_constants(conf)

# HACK: improve this avoiding reusing conf hash
conf[:constants].update(conf[:constants]) do |_, v|
  "<span class=\"notranslate\">#{v}</span>"
end

files = Dir.glob(conf[:file_search_pattern], File::FNM_CASEFOLD)

files.each_with_index do |file, i|

  puts "--------#{file}--------"

  target_file = get_target_file_name(conf, file)

  if File.exist?(target_file)
    puts 'File already exists, ignoring...'
    next
  end

  prepare_target_file(file, target_file)

  target_file_content = File.read(target_file, encoding: conf[:file_encoding])

  original_phrases, phrases = get_phrases(
    conf,
    constants,
    file,
    treated_constants
  )

  raw_translations = translate_phrases(conf, phrases, translator)

  raw_translations.each_with_index do |raw_translation_object, j|
    raw_translation = raw_translation_object.text
    raw_translation.force_encoding('UTF-8').encode!(
      conf[:file_encoding],
      invalid: :replace,
      undef: :replace,
      replace: ' '
    )
    raw_translation.gsub!(%r{<span class="notranslate">|<\/span>}, '')
    puts "Translated:#{raw_translation}"
    # FIXME: char repetition bug here
    target_file_content.gsub!(original_phrases[j][0], raw_translation)
  end

  File.open(target_file, 'w') { |file| file.puts target_file_content }

  puts "---------#{i + 1} de #{files.size} -------"
  sleep 1
end