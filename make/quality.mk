# Formatting, static analysis, tooling tests, the CI gate and planning checks.

##@ Quality
.PHONY: format format-check tidy lint-shell tools-test ci
format: ready ## Apply clang-format to first-party C++ and CUDA files
	clang-format -i $(CXX_FILES)

format-check: ready ## Fail when clang-format would change a file
	clang-format --dry-run -Werror $(CXX_FILES)

tidy: ready ## Run clang-tidy on src/ with a preset's compile database [PRESET=host-debug]
	@test -f $(BUILD_ROOT)$(PRESET)/compile_commands.json || \
	  { echo "make: $(BUILD_ROOT)$(PRESET)/compile_commands.json missing; run make check PRESET=$(PRESET)" >&2; \
	    exit 1; }
	clang-tidy -p $(BUILD_ROOT)$(PRESET) --quiet $(filter src/%.cc,$(CXX_FILES))

lint-shell: ready ## Run shellcheck on the repository's shell scripts
	shellcheck $(SH_FILES)

tools-test: ready ## Run the tests of the repository tooling
	sh $(PROJECT_ROOT)/tools/tests/run.sh

ci: ready ## Required gate before accepting a task; CI runs it
	$(MAKE) format-check
	$(MAKE) lint-shell
	$(MAKE) check PRESET=host-debug
	$(MAKE) check PRESET=host-asan
	$(MAKE) tidy PRESET=host-debug
	$(MAKE) tools-test
	$(MAKE) lint-spec-plan
	$(MAKE) lint-doc-links

##@ Planning
.PHONY: plan-status lint-spec-plan lint-doc-links task-start task-close
plan-status: ## Report open tasks and the next eligible task
	@sh $(PROJECT_ROOT)/tools/plan.sh status

lint-spec-plan: ## Check that the capability registry, plan and records agree
	@sh $(PROJECT_ROOT)/tools/plan.sh lint

lint-doc-links: ## Check relative Markdown links and anchors
	@sh $(PROJECT_ROOT)/tools/doc-links.sh

task-start: ## Create and index the record for an eligible agent task: TASK=<id>
	@sh $(PROJECT_ROOT)/tools/plan.sh start $(TASK)

task-close: ## Retire an accepted task and point references at its record: TASK=<id>
	@sh $(PROJECT_ROOT)/tools/plan.sh close $(TASK)
