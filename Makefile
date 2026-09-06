JULIA ?= julia
PROJECT := --project=.

.PHONY: instantiate test validate run inspect clean

instantiate:
	$(JULIA) $(PROJECT) -e 'using Pkg; Pkg.instantiate()'

test:
	$(JULIA) $(PROJECT) -e 'using Pkg; Pkg.test()'

validate:
	$(JULIA) $(PROJECT) scripts/validate_corpus.jl

run:
	$(JULIA) $(PROJECT) scripts/run_pipeline.jl

inspect:
	$(JULIA) $(PROJECT) scripts/inspect_concepts.jl

clean:
	rm -f results/report.md results/run_metadata.toml
	rm -f results/tables/*.csv results/figures/*.svg results/embeddings/*.csv
