d = Date.new(2015, 10, 19)

Entry.where("created_at > ?", d).update_all(confirmed: true)

Entry.joins(:comments).where("comments.comment" => "ABOVE RED LINE").update_all(confirmed_true)