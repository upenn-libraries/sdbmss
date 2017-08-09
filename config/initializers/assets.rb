# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w( extras.js extras.css development.js loader.js )

# image assets aren't precompiled by default (this is a change in
# Rails 4, possibly?) so we add them here.
Rails.application.config.assets.precompile << /\.(?:png|jpg|jpeg|gif)\z/
Rails.application.config.assets.precompile += %w( favicon.ico )