# Configure, build and test presets on the host and under qemu-user; the same gates on every
# supported Ubuntu release in clean containers; run and clean.

##@ Build
.PHONY: check cross cross-one matrix matrix-one run clean
check: ready ## Configure, build and test one preset [PRESET=host-debug]
	cmake --preset $(PRESET) -DAGENT_BUILD_TESTS=ON
	cmake --build --preset $(PRESET)
	ctest --preset $(PRESET) --parallel $(TEST_JOBS)

cross: ready ## Build device targets and run their tests under qemu-user [TARGET=rpi5]
	$(if $(filter-out $(CROSS_TARGETS),$(TARGET)),$(error unknown cross target "$(TARGET)" \
	  (known: $(CROSS_TARGETS))))
	@set -e; for t in $(or $(TARGET),$(CROSS_TARGETS)); do $(MAKE) cross-one TARGET=$$t; done

cross-one:
	$(MAKE) check PRESET=$(preset_$(TARGET))-debug

matrix: ## Run CMD (default: make ci cross) on Ubuntu 24.04 and 26.04 in clean containers [UBUNTU=26.04]
	$(if $(filter-out $(UBUNTU_RELEASES),$(UBUNTU)),$(error unknown Ubuntu release "$(UBUNTU)" \
	  (known: $(UBUNTU_RELEASES))))
	@command -v docker >/dev/null 2>&1 || { echo "make: make matrix needs docker" >&2; exit 1; }
	@set -e; for u in $(UBUNTU); do $(MAKE) matrix-one UBUNTU=$$u; done

matrix-one:
	docker build --build-arg UBUNTU=$(UBUNTU) -t $(APP)-dev:ubuntu-$(UBUNTU) \
	  -f $(PROJECT_ROOT)/tools/docker/dev.Dockerfile $(PROJECT_ROOT)/tools
	docker run --rm --init --user $$(id -u):$$(id -g) -e HOME=/tmp \
	  -e AGENT_BUILD_PREFIX=ubuntu-$(UBUNTU)/ -e AGENT_MAX_JOBS -v $(PROJECT_ROOT):/src -w /src \
	  $(APP)-dev:ubuntu-$(UBUNTU) sh -c '$(CMD)'

run: ready ## Build host-debug and run the command with ARGS (default: version)
	cmake --preset host-debug
	cmake --build --preset host-debug --target $(APP)
	$(BUILD_ROOT)host-debug/src/$(APP) $(ARGS)

clean: ## Remove build trees, release archives and downloaded test sources
	rm -rf $(PROJECT_ROOT)/build $(DIST_DIR) $(PROJECT_ROOT)/.cache/fetchcontent
