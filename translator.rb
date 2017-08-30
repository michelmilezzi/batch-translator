require 'fileutils'
require 'yaml'
require 'google/cloud/translate'

conf = YAML.load_file(ARGV[0].nil? ? 'translator.yml' : ARGV[0])

# TODO: validate confs

translator = Google::Cloud::Translate.new key: conf[:google_translate_api_key], retries: 10, timeout: 120

new_cons = {}

#Cria o hash de constantes
#Se a constante começar com uppercase então assume que é um nome próprio (somente vai casar com valor exato)
#Se a constante começar com lowercase assume que é um substantivo qualquer (casando com lowercase e uppercase)
conf[:constants].each do |k, v|
  new_cons[k] = v
  new_cons[k.capitalize] = v unless /[[:upper:]]/ =~ k
end

#Cria a expressão regular a partir das constantes
constants = Regexp.new(
  new_cons.keys.join('|')
)

#Atualiza os values do hash das constantes para incluir a tag de notranslate da API do Google
conf[:constants].update(conf[:constants]) do |_, v|
  "<span class=\"notranslate\">#{v}</span>"
end

#Varre os arquivos a serem parseados conforme o pattern configurado
files = Dir.glob(conf[:file_search_pattern], File::FNM_CASEFOLD)

files.each_with_index do |file, i|
  puts "--------#{file}--------"

  #Pega o path do arquivo
  source_path = File.expand_path(file)

  #Substitui o diretório de origem pelo de destino para gerar o path final
  target_path = source_path.sub conf[:source_dir], conf[:target_dir]

  #Se o arquivo existe passa para o próximo
  if File.exist?(target_path)
    puts 'File already exists, ignoring...'
    next
  end

  #Cria os diretórios de destino
  FileUtils.mkdir_p(File.dirname(target_path))

  #Copia o arquivo original para o destino
  FileUtils.cp(file, target_path)

  #Lê o conteúdo do arquivo  
  target_file_content = File.read(target_path, encoding: conf[:file_encoding])

  phrases = []

  #Realiza o parse do arquivo conforme o pattern configurado
  original_phrases = File.read(file, encoding: conf[:file_encoding]).scan(conf[:text_chunks_pattern])

  original_phrases.each do |phrase|
    #Força o encoding para UTF-8 a fim de enviar para API do Google e evitar problema com a codificação original do arquivo
    #TODO: Testar se o encoding é diferente de UTF-8  
    encoded = phrase[0].force_encoding(conf[:file_encoding]).encode('utf-8', invalid: :replace, undef: :replace,  replace: ' ' )
    #Adiciona a tag notranslate para as constantes encontradas na frase
    phrases << encoded.gsub(constants, new_cons)
  end

  raw_translations = []

  until phrases.empty?
    
    #Retira 30 frases do array e envia para a tradução
    tmp = translator.translate(phrases.slice!(0..29), from: conf[:source_language], to: conf[:target_language], format: :text)

    if tmp.is_a?(Array)
      raw_translations.concat tmp
    else
      raw_translations << tmp
    end

  end

  raw_translations.each_with_index do |raw_translation_object, j|
    raw_translation = raw_translation_object.text
    #Converte para o encoding de destino
    raw_translation.force_encoding('utf-8').encode!(conf[:file_encoding], invalid: :replace, undef: :replace,  replace: ' ' )
    #Remove a tag nostranslate das constantes
    raw_translation.gsub!(%r{<span class="notranslate">|<\/span>}, '')
    puts "Translated:#{raw_translation}"
    #Substitui a frase no conteúdo de destino
    target_file_content.gsub!(original_phrases[j][0], raw_translation)
  end

  #Escreve no arquivo de destino
  File.open(target_path, 'w') { |file| file.puts target_file_content }

  puts "---------#{i+1} de #{files.size} -------"
  sleep 1
end