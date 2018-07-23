require 'bunny'
require 'net/http'
require 'uri'
require 'json'

#HOST = "165.123.105.243"
HOST = 'rabbitmq'

attempts = 0

begin
  connection = Bunny.new(:host => HOST, :port => 5672, :user => ENV["RABBIT_USER"], :pass => ENV["RABBIT_PASSWORD"], :vhost => "/")
  status = connection.start
rescue Bunny::TCPConnectionFailedForAllHosts
  puts 'Connection failed: TCPConnectionFailedForAllHosts'
end

while (status == nil) do
  sleep 10
  begin
    status = connection.start
  rescue Bunny::TCPConnectionFailedForAllHosts
    puts "Connection retry ##{attempts} failed: TCPConnectionFailedForAllHosts"
  end
  attempts += 1
  if attempts > 10
    puts "Connection attemps failed 10 times, stopping"
    break
  end
end

channel = connection.create_channel
queue = channel.queue("sdbm")

uri = URI.parse("http://jena:3030/sdbm/update")
http = Net::HTTP.new(uri.host, uri.port)

begin
  puts '[] Waiting for messages. Q: CTRL-C'
  queue.subscribe(block: true) do |_delivery_info, _properties, body|
    #puts " [x] Received: #{body}, #{_delivery_info}, #{_properties}"
    # turn RDF into queries...
    puts "Receieved message."
    message = JSON.parse(body)
    if message['action'] == "destroy"
      puts "destroy!!"
      query = %Q(
        PREFIX sdbm: <https://sdbm.library.upenn.edu/>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

        DELETE { ?subject ?predicate ?object }
        WHERE {
          BIND (<https://sdbm.library.upenn.edu/#{message['model_class']}/#{message['id']}> as ?subject) .
          OPTIONAL { ?subject ?predicate ?object }
        }
      )

      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data({"update" => query})
      request.basic_auth("admin",  ENV["ADMIN_PASSWORD"])
      response = http.request(request)
      puts "response:  #{response} #{query}"      
    elsif message['action'] == "update"
      puts "update"
      query = %Q(
        PREFIX sdbm: <https://sdbm.library.upenn.edu/>        
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
      )
      message['fields'].each do |field, new_value|
        predicate = "sdbm:#{message['model_class']}_#{field}"        
        query += %Q(
          DELETE { ?subject #{predicate} ?object } 
          INSERT { ?subject #{predicate} #{new_value} } 
          WHERE { 
            BIND (<https://sdbm.library.upenn.edu/#{message['model_class']}/#{message['id']}> as ?subject) .
            OPTIONAL { ?subject #{predicate} ?object }
          };

        )
      end
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data({"update" => query})
      request.basic_auth("admin", ENV["ADMIN_PASSWORD"])
      response = http.request(request)          
      #response = Net::HTTP.post_form(uri, {"update" => query})
      puts "response:  #{response} #{query}"  
    else
      puts "OTHER: #{message}"
    end
=begin    
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
      
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data({"update" => query})
      request.basic_auth("admin",  ENV["ADMIN_PASSWORD"])
      response = http.request(request)
      #response = Net::HTTP.post_form(uri, {"update" => query})
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
          request = Net::HTTP::Post.new(uri.request_uri)
          request.set_form_data({"update" => query})
          request.basic_auth("admin", ENV["ADMIN_PASSWORD"])
          response = http.request(request)          
          #response = Net::HTTP.post_form(uri, {"update" => query})
          puts "response:  #{response} #{triple}, #{query}"    
        end
      end
    end
=end    
  end
rescue Interrupt =>
  connection.close
  exit(0)
end      