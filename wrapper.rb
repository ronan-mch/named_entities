require 'nokogiri'
require 'net/http'
require 'json'

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

class AuthorityObject
	def initialize(text, type)
		@name = text
		@type = type
		make_search
	end

	def name
		@name
	end

	def type
		@type
	end

	def link
		"http://viaf.org/viaf/AutoSuggest?query=#{@name}"
	end

	def make_search
		s = "http://viaf.org/viaf/AutoSuggest?query=" + URI.escape(@name)
		uri = URI(s)
		response = Net::HTTP.get(uri)
		j = JSON.parse(response)
		@best_guess = j['result'][0] if j['result']
	end

	def best_guess
		@best_guess
	end
end	

class Wrapper

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
		combined_entities.uniq
	end	

	def call(input_file)

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
		combined_auth = {organization: [], person: [], location: []}
		combined_entities.each_key do |key|
			combined_entities[key].each do |ent|
				auth = AuthorityObject.new(ent, key)
				combined_auth[key] << auth
			end
		end

		combined_auth
	end
end