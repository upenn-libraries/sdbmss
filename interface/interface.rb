require 'bunny'
require 'net/http'
require 'uri'
require 'json'

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
  puts 'Waiting for messages. Q: CTRL-C'
  queue.subscribe(block: true) do |_delivery_info, _properties, body|
    message = JSON.parse(body)
    if message['action'] == "destroy"
      query = %Q(
        PREFIX sdbm: <https://sdbm.library.upenn.edu/>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

        DELETE { ?subject ?predicate ?object }
        WHERE {
          BIND (<https://sdbm.library.upenn.edu/#{message['model_class']}/#{message['id']}> as ?subject) .
          OPTIONAL { ?subject ?predicate ?object }
        }
      )
      begin
        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data({"update" => query})
        request.basic_auth("admin",  ENV["ADMIN_PASSWORD"])
        response = http.request(request)
        if response.code != 200
          puts "PROBLEM: #{response} #{query}"
        end
        status_queue = channel.queue("sdbm_status")
        status_queue.publish({id: message['response_id'], code: response.code, message: response.message}.to_json)
      rescue Exception => err
        status_queue = channel.queue("sdbm_status")
        status_queue.publish({id: message['response_id'], code: "404", message: err.to_s }.to_json)
      end
    elsif message['action'] == "update"
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
      query += %Q(
        DELETE { ?subject <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ?object } 
        INSERT { ?subject <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <https://sdbm.library.upenn.edu/#{message['model_class']}> } 
        WHERE { 
          BIND (<https://sdbm.library.upenn.edu/#{message['model_class']}/#{message['id']}> as ?subject) .
          OPTIONAL { ?subject <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ?object }
        };
      )
      begin
        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data({"update" => query})
        request.basic_auth("admin", ENV["ADMIN_PASSWORD"])
        response = http.request(request) 
        if response.code != 200
          puts "PROBLEM: #{response} #{query}"
        end
        status_queue = channel.queue("sdbm_status")
        status_queue.publish({id: message['response_id'], code: response.code, message: response.message}.to_json)
      rescue Exception => err
        status_queue = channel.queue("sdbm_status")
        status_queue.publish({id: message['response_id'], code: "404", message: err.to_s }.to_json)
      end     
    else
      puts "OTHER: #{message}"
    end    
  end
rescue Interrupt => err
  connection.close
  exit(0)
end