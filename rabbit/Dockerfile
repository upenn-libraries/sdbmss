FROM rabbitmq:latest

CMD rabbitmqctl add_user sdbm sdbm
CMD rabbitmqctl set_user_tags sdbm administrator
CMD rabbitmqctl set_permissions -p / sdbm ".*" ".*" ".*"

CMD rabbitmq-server
#RUN ruby interface.rb
# TODO to check rabbitmq server
# TODO process messages

#CMD ruby interface.rb
