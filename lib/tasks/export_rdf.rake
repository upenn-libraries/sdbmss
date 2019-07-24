desc "Export to RDF"


namespace :sparql do
	task :test => :environment do

		entities = [ Name, Place, Language, Source, DericciLink, DericciRecord, Entry, EntryArtist, EntryAuthor, EntryDate, EntryLanguage, EntryManuscript, EntryMaterial, EntryPlace, EntryScribe, EntryTitle, EntryUse, Manuscript, NamePlace, Provenance, Sale, SaleAgent, SourceAgent ]
		
		File.open("test.ttl", "w") do |f|
			f.puts %Q(
@prefix owl:   <http://www.w3.org/2002/07/owl#> .
@prefix rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix xsd:   <http://www.w3.org/2001/XMLSchema#> .
@prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema#> .
@prefix sdbm:  <https://sdbm.library.upenn.edu#> .
			)
			entities.each do |entity|
				class_name = entity.to_s.underscore.pluralize
				puts "Processisng: #{class_name}"
				entity.where("id < 10000").each do | instance |
					f.puts "<https://sdbm.library.upenn.edu/#{class_name}/#{instance.id}> sdbm:#{class_name}_id #{instance.id} ."
					f.puts "<https://sdbm.library.upenn.edu/#{class_name}/#{instance.id}> rdf:type sdbm:#{class_name} ."
					instance.to_rdf[:fields].each do | key, value |
						f.puts "<https://sdbm.library.upenn.edu/#{class_name}/#{instance.id}> sdbm:#{class_name}_#{key} #{value.gsub("\r\n", '').gsub("\\", '')} ."
					end
					f.puts ""
				end
			end
		end
	end
end
