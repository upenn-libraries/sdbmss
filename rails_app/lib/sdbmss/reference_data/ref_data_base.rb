module SDBMSS::ReferenceData
  # These helpers exist for seed/bootstrap code, not normal app queries.
  # We intentionally bypass default scopes here because soft-deleted rows
  # are hidden from ordinary lookups but still participate in unique indexes.
  class RefDataBase
    def reindex(entry)
      # In test/dev seeding we only need the record indexed, not
      # reloaded; guarding avoids RecordNotFound if the row vanished.
      return unless entry && entry.persisted?

      Sunspot.index entry
    end

    def lransom
      user = User.find_by(email: "lransom@upenn.edu") || User.find_by(username: "lransom")
      return user if user.present?

      User.create!(
        username: "lransom",
        email: "lransom@upenn.edu",
        password: "12345678",
        password_confirmation: "12345678"
      )
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique, Mysql2::Error => e
      raise if e.is_a?(Mysql2::Error) && e.message !~ /Duplicate entry|Deadlock/

      User.find_by(email: "lransom@upenn.edu") || User.find_by(username: "lransom")
    end

    def find_or_create_unscoped(model_class, attrs)
      record = model_class.unscoped.where(attrs).first
      return record if record

      model_class.create!(attrs)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      model_class.unscoped.where(attrs).first
    end

    def find_or_create_name_by_flag(name, flag)
      record = Name.unscoped.where(name: name).first
      if record
        if !record.send(flag)
          record.send("#{flag}=", true)
          record.save!
        end
        return record
      end

      attrs = { name: name, flag => true }
      Name.create!(attrs)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique, Mysql2::Error => e
      raise if e.is_a?(Mysql2::Error) && e.message !~ /Duplicate entry|Deadlock/

      record = Name.unscoped.where(name: name).first
      if record && !record.send(flag)
        record.send("#{flag}=", true)
        record.save!
      end
      record
    end

    def find_or_create_agent(name)
      find_or_create_name_by_flag(name, :is_provenance_agent)
    end

    def find_or_create_artist(name)
      find_or_create_name_by_flag(name, :is_artist)
    end

    def find_or_create_author(name)
      find_or_create_name_by_flag(name, :is_author)
    end

    def find_or_create_scribe(name)
      find_or_create_name_by_flag(name, :is_scribe)
    end
  end
end
