## GCP

Here’s a battle-tested setup that catches vendor quirks (like Cloud SQL tiers/editions) before you run apply.

⸻

1) Add provider-specific linting (local + CI)

Use TFLint with the Google ruleset. It flags many GCP-specific gotchas that terraform validate can’t (wrong arguments, region/feature mismatches, etc.). Run it in pre-commit and CI:

.tflint.hcl

plugin "google" {
  enabled = true
  source  = "github.com/terraform-linters/tflint-ruleset-google"
  # pin for reproducibility; update on your schedule
  version = ">= 0.37.0"
}

# optional: adjust severities / enable extra rules
config {
  call_module_type = "all"
}

Then:

tflint --init
tflint --format compact

TFLint + the Google ruleset is well maintained and purpose-built for these checks.  ￼

⸻

2) Fail fast with plan-time preconditions (Terraform ≥1.2)

Terraform lets you attach precondition checks to resources/data sources. They evaluate during plan, so you can block bad combos (e.g., ENTERPRISE_PLUS + db-n1-*).  ￼

For Cloud SQL, the Google provider exposes data.google_sql_tiers, which lists valid tiers for your project/region. Use it to assert your chosen tier is allowed for the current edition/region before apply:  ￼

# Fetch available tiers for the region/project
data "google_sql_tiers" "this" {
  project = var.project_id
  region  = var.region
}

# Example: ensure tier is valid and edition-compatible at plan-time
resource "google_sql_database_instance" "main" {
  name             = var.instance_name
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    edition = var.edition          # e.g., "ENTERPRISE_PLUS" or "ENTERPRISE"
    tier    = var.tier             # e.g., "db-perf-optimized-N-2" (✅) or "db-n1-standard-2" (❌)
  }

  lifecycle {
    precondition {
      condition     = contains([for t in data.google_sql_tiers.this.tiers : t.tier], var.tier)
      error_message = "Tier ${var.tier} is not offered in ${var.region} for project ${var.project_id}."
    }
    precondition {
      condition = (
        (var.edition == "ENTERPRISE_PLUS" && can(regex("^db-perf-optimized-", var.tier))) ||
        (var.edition != "ENTERPRISE_PLUS")                                  # relax or add other patterns as needed
      )
      error_message = "Edition ${var.edition} requires a 'db-perf-optimized-*' tier. Update var.tier."
    }
  }
}

Tip: if a provider lacks a suitable data source, you can still validate with the external data source and a tiny script that shells out to a vendor CLI (e.g., gcloud sql tiers list --format=json) and returns JSON for your preconditions to check.  ￼

⸻

3) Write tests for configurations (matrix your variables)

Terraform 1.6 introduced terraform test (.tftest.hcl). You can run speculative plans over a matrix of var combos and assert they pass your preconditions—no real apply needed. Great for catching edition/tier/region mismatches in CI.  ￼

example.tftest.hcl

run "enterprise_plus_requires_perf_optimized" {
  command = plan
  variables = {
    edition = "ENTERPRISE_PLUS"
    tier    = "db-n1-standard-2"
  }
  expect_failures = [
    resource.google_sql_database_instance.main
  ]
}

run "enterprise_plus_with_perf_optimized_ok" {
  command = plan
  variables = {
    edition = "ENTERPRISE_PLUS"
    tier    = "db-perf-optimized-N-2"
  }
}


⸻

4) Keep a canary apply cheap and automated

Some API nuances only surface in a real apply. Automate a throwaway project (or folder with org-policy/budget limits) that runs a minimal end-to-end “smoke” apply/destroy on PRs or nightly:
	•	Separate GCP project with limited quotas/budget alerts.
	•	Tiny resources (or count = 0/1 behind a flag).
	•	terraform apply -auto-approve followed by terraform destroy if the plan succeeds.

This catches real provider API changes with minimal cost, without blocking day-to-day.

⸻

5) Version discipline + proactive upgrades
	•	Pin required_providers and Terraform versions so behavior doesn’t change under your feet; periodically run a scheduled CI job that does terraform init -upgrade, tflint, and terraform test against the canary to detect breaking changes early.

⸻

6) Quick wins you can drop in today
	•	Variable validation as a first line of defense:

variable "edition" {
  type = string
  validation {
    condition     = contains(["ENTERPRISE", "ENTERPRISE_PLUS"], var.edition)
    error_message = "Edition must be ENTERPRISE or ENTERPRISE_PLUS."
  }
}


	•	Pre-commit hooks: terraform_fmt, terraform_validate, tflint. (pre-commit-terraform has ready-made hooks.)
	•	Module guardrails: put the preconditions inside your shared module so every consumer benefits.

⸻

Why this helps with your exact errors
	•	“Invalid Tier (db-n1-standard-2) for (ENTERPRISE_PLUS)… use db-perf-optimized-N-”*
→ The precondition + regex("^db-perf-optimized-") check rejects this at plan time. data.google_sql_tiers guarantees the value actually exists in the region/project.  ￼
	•	“Only custom or shared-core instance Billing Tier type allowed for PostgreSQL”
→ Encode an edition/database-version → allowed tier patterns map and assert it in a precondition. If Google adjusts availability, refreshing data.google_sql_tiers will make the plan fail instead of the apply.

## AWS

Yes — there is a dedicated ruleset for TFLint covering Terraform-AWS configurations: the plugin tflint‑ruleset‑aws (hosted under terraform-linters/tflint-ruleset-aws).  ￼

✅ What it covers
	•	The ruleset “focus[es] on possible errors and best practices about AWS resources”.  ￼
	•	Example: It catches something like you using an invalid instance_type for aws_instance, even though Terraform syntax is valid but the AWS API would reject it.  ￼
	•	Contains 700+ rules for AWS resources.  ￼
	•	You can configure it via your .tflint.hcl just as with other plugins.  ￼

⚠ What it doesn’t do (or may not fully do)
	•	While it catches many provider-specific mismatches (like invalid properties, bad types, deprecated settings), it may not cover every single nuance of AWS API/edition/region-specific restrictions.
	•	For example, if AWS introduces a new restriction (e.g., a region stops allowing a particular machine type) you might still hit it at apply unless the ruleset has been updated to catch that.
	•	Custom or advanced policies (mappings of edition → allowed tier, or cross-resource interplay) may still require custom rules or “precondition” style checks (as discussed earlier).
	•	Some rules may not be enabled by default, or may require explicit configuration to enforce.  ￼

🔧 How to enable it in your project

Here’s a minimal .tflint.hcl snippet:

plugin "aws" {
  enabled = true
  version = "0.43.0"                  # pick a version you are comfortable with
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Optionally you can disable specific rules you don’t want
rule "aws_instance_invalid_type" {
  enabled = true
}

Then run:

tflint --init
tflint --recursive

🎯 Recommended next step for you

Since you’re dealing with subtle “apply-time only” failures (e.g., edition/tier mismatches), I’d suggest:
	1.	Enable tflint-ruleset-aws in your codebase (if you haven’t yet).
	2.	Browse the rules list and see if there are existing rules that catch the specific “edition vs tier” combinations you hit. The repository has docs for each rule.  ￼
	3.	If no existing rule covers your exact nuance (say “if edition = X then tier must match pattern Y”), you can write a custom rule or add a “precondition” in Terraform (as earlier discussed) for that check.
	4.	Integrate tflint into your CI/PR pipeline so these mismatches get caught before apply.
