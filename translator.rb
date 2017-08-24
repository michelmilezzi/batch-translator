require 'fileutils'
require 'yaml'
require 'google/cloud/translate'

conf = YAML.load_file('translator.yml')

# TODO: validate confs

translator = Google::Cloud::Translate.new(
  key: conf[:google_translate_api_key]
)

new_cons = {}

conf[:constants].each do |k, v|
  new_cons[k] = v
  new_cons[k.capitalize] = v unless /[[:upper:]]/ =~ k
end

constants = Regexp.new(
  new_cons.keys.join('|')
)

conf[:constants].update(conf[:constants]) do |_, v|
  "<span class=\"notranslate\">#{v}</span>"
end

files = Dir.glob(conf[:file_search_pattern], File::FNM_CASEFOLD)

files.each_with_index do |file, i|
  puts "--------#{file}--------"
  source_path = File.expand_path(file)
  target_path = source_path.sub conf[:source_dir], conf[:target_dir]
  FileUtils.mkdir_p(File.dirname(target_path))
  FileUtils.cp(file, target_path)
  target_file_content = File.read(target_path, encoding: conf[:file_encoding])

  phrases = []
  original_phrases = File.read(file, encoding: conf[:file_encoding]).scan(conf[:text_chunks_pattern])

  original_phrases.each do |phrase|
    #tmp = coder.decode phrase[0]
    tmp = phrase[0].force_encoding("windows-1251").encode(conf[:file_encoding], invalid: :replace, undef: :replace,  replace: ' ' )  
    phrases << tmp.gsub(constants, new_cons)
  end

  raw_translations = []
  returned_translation = []

  #returned_translation << translator.translate(phrases.slice!(0..9), from: conf[:source_language], to: conf[:target_language]) until phrases.empty?
  #returned_translation = translator.translate phrases, from: conf[:source_language], to: conf[:target_language]

  until phrases.empty?  do
    tmp = translator.translate(phrases.slice!(0..19), from: conf[:source_language], to: conf[:target_language])
    puts tmp
    returned_translation.concat tmp
  end

  raw_translations.concat returned_translation if returned_translation.is_a?(Array)
  raw_translations << returned_translation unless returned_translation.is_a?(Array)

  raw_translations.each_with_index do |raw_translation_object, j|
    raw_translation = raw_translation_object.text
    raw_translation.encode!(conf[:file_encoding])
    raw_translation.gsub!(%r{<span class="notranslate">|<\/span>}, '')
    puts "Traduzido:#{raw_translation}"
    target_file_content.gsub!(original_phrases[j][0], raw_translation)
  end

  File.open(target_path, 'w') { |file| file.puts target_file_content }

  # raw_translation = translator.translate phrases, from: conf['source_language'], to: conf['target_language']
  # puts raw_translation.class
  puts "---------#{i+1} de #{files.size} -------"
  sleep 0.25
end