# dartsass-sprockets overrides Sprockets::SassProcessor::Functions but omits
# font_path / font_url, which font-awesome-sass needs via _font-awesome-sprockets.scss.
# Re-add them by delegating to asset_path with type: :font.
SassC::Rails::SassTemplate::Functions.module_eval do
  def font_path(path)
    asset_path(path, type: :font)
  end

  def font_url(path)
    asset_url(path, type: :font)
  end
end
