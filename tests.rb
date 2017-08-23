phrase = 'Brahmin are a mutated breed of cows. Nobody likes brahmin meat.'

conf_constants = { 'brahmin' => 'vaca louca'}

puts conf_constants
puts conf_constants.class

new_cons = {}

conf_constants.each do |k, v|
  new_cons[k] = v
  new_cons[k.capitalize] = v unless /[[:upper:]]/ =~ k
end

constants = Regexp.new(
  new_cons.keys.join('|')
)

puts constants

puts '------------------'

phrase.gsub! constants, new_cons
phrase[0] = phrase[0].upcase

puts phrase