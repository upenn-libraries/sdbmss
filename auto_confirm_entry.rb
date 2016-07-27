d = Date.new(2015, 10, 19)

Entry.where("created_at > ?", d).update_all(unverified_legacy_record: false)

Entry.joins(:comments).where("comments.comment" => "ABOVE RED LINE").update_all(unverified_legacy_record: false)