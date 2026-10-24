# Reproducible release archives: one per target, built from its release preset.

##@ Distribution
.PHONY: dist
dist: ready ## Release archive into dist/ [TARGET=linux-amd64]; TAG=vX.Y.Z requires that version
	$(eval T := $(or $(TARGET),linux-amd64))
	$(if $(filter $(T),$(TARGETS)),,$(error unknown target "$(T)" (known: $(TARGETS))))
	$(if $(TAG),$(if $(filter v$(VERSION),$(TAG)),,$(error tag $(TAG) does not match project \
	  version $(VERSION) (want v$(VERSION)))))
	$(if $(filter linux-amd64,$(T)),$(if $(filter x86_64,$(shell uname -m)),,$(error \
	  linux-amd64 builds natively on x86_64 only)))
	$(eval P := $(preset_$(T))-release)
	$(eval BASE := $(APP)-$(VERSION)-$(T))
	cmake --preset $(P) -DAGENT_BUILD_TESTS=OFF -DAGENT_TARGET_NAME=$(T)
	cmake --build --preset $(P)
	rm -rf $(DIST_DIR)/$(BASE)
	cmake --install $(BUILD_ROOT)$(P) --prefix $(DIST_DIR)/$(BASE) --strip
	tar -C $(DIST_DIR) --sort=name --owner=0 --group=0 --numeric-owner \
	  --mtime=@$(SOURCE_DATE_EPOCH) -I 'gzip -n' -cf $(DIST_DIR)/$(BASE).tar.gz $(BASE)
	rm -rf $(DIST_DIR)/$(BASE)
