json.activities @details do |(date, users)|
  
  json.date date
  json.activities users.as_json

end