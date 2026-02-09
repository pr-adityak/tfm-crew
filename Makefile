.PHONY: docs docs-aws docs-gcp lint

docs: docs-aws docs-gcp
	@echo "Documentation generation complete for all modules!"

docs-aws:
	@echo "Generating documentation for AWS modules..."
	@for dir in modules/aws/*; do \
		if [ -d "$$dir" ]; then \
			echo "Documenting $$dir..."; \
			terraform-docs markdown table --config .terraform-docs.yml $$dir; \
		fi \
	done

docs-gcp:
	@echo "Generating documentation for GCP modules..."
	@for dir in modules/gcp/*; do \
		if [ -d "$$dir" ]; then \
			echo "Documenting $$dir..."; \
			terraform-docs markdown table --config .terraform-docs.yml $$dir; \
		fi \
	done

lint:
	@echo "Running TFLint on all Terraform code..."
	@tflint --recursive
	@echo "TFLint check complete!"
