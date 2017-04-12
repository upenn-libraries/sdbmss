# generate html string for public-facing name-authority fields

module PublicView
  extend ActiveSupport::Concern

  def public_view
    name_authority + observed + certainty_flags
  end

  def name_authority
    ""
  end

  def observed
    observed_name ? "(#{observed_name})" : ""
  end

  def certainty_flags
    ""
  end

end