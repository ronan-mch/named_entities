require 'nokogiri'

class Entity
	def initialize(element)
		@type = element.attribute('entity').value.downcase
		@pos = element.attribute('num').value.to_i
		@text = element.text
		@combined = false
	end

	def type
		@type
	end

	def pos
		@pos
	end

	def text
		@text
	end

	def combined?
		@combined
	end

	def combined=(val)
		@combined = val
	end
end

def combine_entities(entities)
	combined_entities = []
	entities.each_with_index do |entity, index|
		# skip if this entity has already been combined with another
		next if entity.combined?
		combined_entity = entity.text
		counter = 1
		next_entity = entities[index + counter]
		next if next_entity.nil?
		# combine all the consecutive elements
		while next_entity.pos == entity.pos + counter
			combined_entity += " #{next_entity.text}"
			next_entity.combined = true	
			counter += 1
			next_entity = entities[index + counter]
			break if next_entity.nil?
		end
		combined_entities << combined_entity
	end
	combined_entities
end	

input_file = ARGV[0]
if not input_file 
	puts "no input file specified!"
	abort
end

tagged = `java -mx700m -cp "./stanford-ner.jar:" edu.stanford.nlp.ie.crf.CRFClassifier -loadClassifier ./classifiers/english.all.3class.distsim.crf.ser.gz -textFile "#{input_file}" -outputFormat xml`
tagged = "<doc>#{tagged}</doc>"
xml = Nokogiri::XML(tagged)
entities = {organization: [], person: [], location: []}
xml.css('wi').each do |wi|
	entity = Entity.new(wi)
	entity_type = entity.type.to_sym
	if entities.has_key? entity_type
		entities[entity_type] << entity
	end
end

combined_entities = Hash.new
entities.each_key do |key|
	combined_entities[key] = combine_entities(entities[key])
end

puts combined_entities.inspect