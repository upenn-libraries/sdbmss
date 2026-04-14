module SDBMSS::SeedData
  # Seed setup is called repeatedly in tests, so these helpers prefer
  # idempotent lookups over "table is empty" assumptions.
  def self.find_or_create_user(attrs)
    user = User.find_by(email: attrs[:email]) || User.find_by(username: attrs[:username])
    return user if user.present?

    User.create!(attrs)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique, Mysql2::Error => e
    raise if e.is_a?(Mysql2::Error) && e.message !~ /Duplicate entry|Deadlock/

    User.find_by(email: attrs[:email]) || User.find_by(username: attrs[:username])
  end

  def self.find_or_create_page(name, filename)
    page = Page.find_by(filename: filename) || Page.find_by(name: name)
    return page if page.present?

    Page.create!(name: name, filename: filename)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique, Mysql2::Error => e
    raise if e.is_a?(Mysql2::Error) && e.message !~ /Duplicate entry|Deadlock/

    Page.find_by(filename: filename) || Page.find_by(name: name)
  end
end
