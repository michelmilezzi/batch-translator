phrase = 'Brahmin are a mutated breed of cows. Nobody likes brahmin meat.'

conf_constants = { 'brahmin' => 'vaca louca'}

puts conf_constants
puts conf_constants.class

#friend3 = Hash.new
#friend3["name"] = "Sassy"
#friend3["breed"] = "Himalayan cat"

new_cons = Hash.new

conf_constants.each do | k, v|
  new_cons[k] = v
  if !/[[:upper:]]/.match(k) 
    new_cons[k.capitalize] = v  
  end 
end 

# constants = Regexp.new(
#   conf_constants.keys.map do |x|
#     #/[[:upper:]]/.match(x) ? Regexp.escape(x) : "[#{Regexp.escape(x)}|#{Regexp.escape(x.capitalize)}]"
#     #   Regexp.escape('[b|B]rahmin')
# '[b|B]rahmin'
#   end.join('|')
# )

constants = Regexp.new(
  new_cons.keys.join('|')
)

puts constants
#gsub: If the second argument is a Hash, and the matched text is one of its keys, the corresponding value is the replacement string.

puts '------------------'

phrase.gsub! constants, new_cons
phrase[0] = phrase[0].upcase

puts phrase