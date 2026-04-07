# Fix: Blacklight 7.11 uses YAML.safe_load to parse blacklight.yml, but
# Psych 3.1+ rejects YAML aliases (&default / *default) by default.
# Override blacklight_yml to allow aliases.
module Blacklight
  def self.blacklight_yml
    require 'erb'
    require 'yaml'

    return @blacklight_yml if @blacklight_yml
    unless File.exist?(blacklight_config_file)
      raise "You are missing a configuration file: #{blacklight_config_file}. Have you run \"rails generate blacklight:install\"?"
    end

    begin
      blacklight_erb = ERB.new(IO.read(blacklight_config_file)).result(binding)
    rescue StandardError, SyntaxError => e
      raise("#{blacklight_config_file} was found, but could not be parsed with ERB. \n#{e.inspect}")
    end

    begin
      @blacklight_yml = YAML.safe_load(blacklight_erb, aliases: true)
    rescue ArgumentError
      # Older Psych versions don't support the aliases keyword
      @blacklight_yml = YAML.safe_load(blacklight_erb, [], [], true)
    rescue => e
      raise("#{blacklight_config_file} was found, but could not be parsed.\n#{e.inspect}")
    end

    if @blacklight_yml.nil? || !@blacklight_yml.is_a?(Hash)
      raise("#{blacklight_config_file} was found, but was blank or malformed.\n")
    end

    @blacklight_yml
  end
end
