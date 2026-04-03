# Transitional config: keep Rails 4.2 behavior while on 5.2.
# Each line can be flipped to the 5.2 default individually after testing.

# Rails 5.0: belongs_to associations are required by default.
# Set to false to preserve 4.2 behavior (71 belongs_to across 42 models).
Rails.application.config.active_record.belongs_to_required_by_default = false

# Rails 5.0: protect_from_forgery is prepended by default.
Rails.application.config.action_controller.default_protect_from_forgery = false

# Rails 5.0: per-form CSRF tokens.
Rails.application.config.action_controller.per_form_csrf_tokens = false

# Rails 5.0: origin-checking CSRF mitigation.
Rails.application.config.action_controller.forgery_protection_origin_check = false

# Rails 5.2: use authenticated message encryption for cookies.
Rails.application.config.active_support.use_authenticated_message_encryption = false

# Rails 5.2: use SHA1 for message digests (4.2 used MD5).
Rails.application.config.active_support.hash_digest_class = ::Digest::MD5

# Rails 5.2: use authenticated cookie encryption.
Rails.application.config.action_dispatch.use_authenticated_cookie_encryption = false

# Rails 5.2: cache versioning via #cache_version instead of cache key.
Rails.application.config.active_record.cache_versioning = false
