# Toolchain install and report, and the build budget.

##@ Environment
.PHONY: setup doctor jobs
setup: ## Install the full toolchain system-wide with apt (asks for sudo)
	$(PROJECT_ROOT)/tools/setup-ubuntu.sh

doctor: ## Report installed tools and versions against the floors
	@sh $(PROJECT_ROOT)/tools/doctor.sh

jobs: ready ## Print the build budget: compile, link and heavy job pools
	@cmake -P $(PROJECT_ROOT)/cmake/AgentBuildBudget.cmake
