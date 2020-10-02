# Creates connection to the RabbitMQ server (in this case the docker container 'rabbitmq')

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

# Once the connection has been successful, subscribe to the 'sdbm' channel, and create a connection to the Jena query endpoint
# (for future use)

channel = connection.create_channel
queue = channel.queue("sdbm")

uri = URI.parse("http://jena:3030/sdbm/update")
http = Net::HTTP.new(uri.host, uri.port)

# Next, start waiting for incoming messages into the RabbitMQ "mailbox"

begin
  puts 'Waiting for messages. Q: CTRL-C'
  queue.subscribe(block: true) do |_delivery_info, _properties, body|
    message = JSON.parse(body)
    if message['action'] == "destroy"

# The message action will either be "destroy" or "update".  In the case of destroy, the query simply deletes every triple
# with the given entity as its 'subject'.  For update, each field is iterated over and the triple is deleted and rewritten.
# For example, the 'destroy' query is as follows:

      query = %Q(
        PREFIX sdbm: <https://sdbm.library.upenn.edu/>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>

        DELETE { ?subject ?predicate ?object }
        WHERE {
          BIND (<https://sdbm.library.upenn.edu/#{message['model_class']}/#{message['id']}> as ?subject) .
          OPTIONAL { ?subject ?predicate ?object }
        }
      )

# Finally, the query is sent and the response is examined to see if it was successful.  If it fails immediately, this is sent
# back in the response, but most of the time the actual sending is fine.  In this second case, the update is recorded as
# 'sent', since it takes an unknown (to the script) amount of time for the update to be processed.  This is all checked each
# day using the verify_jena rake/cron task.

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

# When the record is updated, the process is the same, but as well as the old triple being deleted (for each triple in the
# record), the new triple is added with the new value.

        query += %Q(
          DELETE { ?subject #{predicate} ?object }
        )

        # Don't insert triples with empty objects
        unless new_value.to_s.empty?
          query += %Q(
          INSERT { ?subject #{predicate} #{new_value} }
          )
        end

        query += %Q(
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

# The message response handling is the same in both cases, however.

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

# And that's it!