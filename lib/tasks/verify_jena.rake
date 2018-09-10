desc "Handle JENA sync verifications"

def resend_destroy(queue, record_id, record_type, response_id)
  message = {
    model_class: record_type.underscore,
    id: record_id,
    response_id: response_id,
    action: "destroy"
  }
  queue.publish(message.to_json)
end

namespace :jena do
  task :verify => :environment do
    begin
      puts "Starting Queue Listening"
      bunny_connection = Bunny.new(:host => 'rabbitmq', :port => 5672, :user => ENV["RABBIT_USER"], :pass => ENV["RABBIT_PASSWORD"], :vhost => "/")
      bunny_connection.start
      ch = bunny_connection.create_channel
      queue = ch.queue("sdbm_status")
      resend_queue = ch.queue("sdbm")
      while queue.message_count > 0 do
        delivery_info, properties, body = queue.pop
        #queue.subscribe do |_delivery_info, _properties, body|
        contents = JSON.parse(body)
        puts "Parsed contents: #{contents}"
        if JenaResponse.exists? contents['id']
          jena_response = JenaResponse.find(contents['id'])
          if contents['code'] == '200'
              puts "Jena Update was Successful!"
              # success, delete
              jena_response.destroy
          else
              if jena_response.tries < 3
                  puts "Failed. Resending..."
                  jena_response.update(status: 0, tries: jena_response.tries + 1, message: "#{contents['code']}: #{contents['message']}")
                  # fix me: handle for DESTROY as well
                  if jena_response.record.present?
                    jena_response.record.update_bunny(jena_response.id)
                  else
                    resend_destroy(resend_queue,response.record_id, response.record_type, response.id)
                      #jena_response.record.destroy_bunny(jena_response.id)
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
        #end
        #sleep 2
      end
      puts "No more messages in queue."
      remaining_responses = JenaResponse.where("tries < 3")
      puts "Remaining responses: #{remaining_responses.count}"
      remaining_responses.each do |response|
        response.update(tries: response.tries + 1)
        if response.record.present?
          response.record.update_bunny(response.id)
        else
          resend_destroy(resend_queue,response.record_id, response.record_type, response.id)
          #response.record.destroy_bunny(response.id)
        end
      end
      ch.close()
    rescue Exception => err
      puts "Error in running verification script: #{err}"
    end
  end
end