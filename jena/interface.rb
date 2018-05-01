require 'bunny'
require 'net/http'
require 'uri'

#HOST = "165.123.105.243"
HOST = 'rabbitmq'

connection = Bunny.new(:host => HOST, :port => 5672, :user => "sdbm", :pass => "sdbm", :vhost => "/")
connection.start

channel = connection.create_channel
queue = channel.queue("sdbm")

uri = URI.parse("http://jena:3030/sdbm/update")

begin
  puts '[] Waiting for messages. Q: CTRL-C'
  queue.subscribe(block: true) do |_delivery_info, _properties, body|
    #puts " [x] Received: #{body}, #{_delivery_info}, #{_properties}"
    # turn RDF into queries...
    lines = body.split("\n").reject { |a| a.to_s.length <= 0 }.map(&:strip)
    subject = lines[0].split(":").last
    if lines[0].include? "DESTROY"
      #puts 'destroy'
      query = %Q(
        PREFIX sdbm: <https://sdbm.library.upenn.edu/>
        DELETE { ?subject ?predicate ?object } 
        WHERE { 
          BIND (<https://sdbm.library.upenn.edu/#{subject}> as ?subject) .  
          OPTIONAL { ?subject ?predicate ?object }
        }
      )
      #puts "URI: #{uri}"
      response = Net::HTTP.post_form(uri, {"update" => query})
      puts "response:  #{response} #{subject}, #{query}"
    else
      #puts 'update'
      lines = lines[1..-1]
      lines.each do |triple|
        triple = triple.split(" ")
        predicate = triple[0]
        object = triple[1..-1].to_a.join(" ")
        if predicate.to_s.length > 0
          query = %Q(
            PREFIX sdbm: <https://sdbm.library.upenn.edu/>
            PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

            DELETE { ?subject #{predicate} ?object } 
            INSERT { ?subject #{predicate} #{object} } 
            WHERE { 
              BIND (<https://sdbm.library.upenn.edu/#{subject}> as ?subject) .  
              OPTIONAL { ?subject #{predicate} ?object }
            }
          )
          #puts "URI: #{uri} >> #{query} >> #{triple} >> #{predicate} >> #{object}"
          response = Net::HTTP.post_form(uri, {"update" => query})
          puts "response:  #{response} #{triple}, #{query}"    
        end
      end
    end
  end
rescue Interrupt =>
  connection.close
  exit(0)
end      