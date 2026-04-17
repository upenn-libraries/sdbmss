Rails.autoloaders.main.inflector.inflect(
  "sdbmss" => "SDBMSS",
  "csv" => "CSV",
  "tools_cli" => "ToolsCLI",
  "viaf" => "VIAF",
  "viaf_reconciliation" => "VIAFReconciliation",
  "ids" => "IDS"
)

# These files don't follow Zeitwerk naming conventions, they reopen parent
# modules and are loaded explicitly via require_relative.
Rails.autoloaders.main.ignore(
  Rails.root.join("lib", "sdbmss", "reference_data"),
  Rails.root.join("lib", "sdbmss", "seed_data")
)
