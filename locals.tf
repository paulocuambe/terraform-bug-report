locals {
  project_slug = "bug-repro"

  common_tags = {
    Confidentiality = "C3"
    PII             = "No"
    BusinessUnit    = "DEV"
    TaggingVersion  = "V2.4"
    Tribe           = "Debug"
    ManagedBy       = "test@company.com"
    SecurityZone    = "A"
  }
}
