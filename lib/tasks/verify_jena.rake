desc "Handle JENA sync verifications"
namespace :jena do
  task :verify => :environment do
    puts "Starting Queue Listening"
    bunny_connection = Bunny.new(:host => 'rabbitmq', :port => 5672, :user => ENV["RABBIT_USER"], :pass => ENV["RABBIT_PASSWORD"], :vhost => "/")
    bunny_connection.start
    ch = bunny_connection.create_channel
    queue = ch.queue("sdbm_status")
    while queue.message_count > 0 do
      queue.subscribe do |_delivery_info, _properties, body|
        contents = JSON.parse(body)
        puts "Parsed contents: #{contents}"
        if (jena_response = JenaResponse.find(contents['id']))
          if contents['code'] == '200'
              puts "Jena Update was Successful!"
              # success, delete
              jena_response.destroy
          else
              if jena_response.tries < 3
                  puts "Failed. Resending..."
                  jena_response.update(tries: jena_response.tries + 1, message: "#{contents['code']}: #{contents['message']}")
                  # fix me: handle for DESTROY as well
                  if jena_response.record.present?
                      jena_response.record.update_bunny(jena_response.id)
                  else
                      jena_response.record.destroy_bunny(jena_response.id)
                  end
              else
                  puts "Failed. Response record retained."
                  jena_response.update(status: -1)
              end
              # resend, increment sent-counter
          end
        else
            # no longer exists
        end
      end
      sleep 2
    end
    puts "No more messages in queue."
    ch.close()
    puts JenaResponse.count
  end
end