Entry.joins(:comments).where("comments.comment" => "ABOVE RED LINE").each do |entry|
  entry.update_column(:confirmed, true)
end

# question -> what is the cut-off date for auto-redlining records