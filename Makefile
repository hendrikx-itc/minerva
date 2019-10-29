ECONDEXPANSION:

BIN_DIR=$(DESTDIR)/usr/bin
MINERVA_SHARE_DIR=$(DESTDIR)/usr/share/minerva

SCRIPTS=migrate-minerva
SCRIPT_FILES=$(addprefix $(BIN_DIR)/, $(SCRIPTS))
SRC_FILES=$(addprefix $(MINERVA_SHARE_DIR)/,$(wildcard src/*.sql))
MIGRATION_FILES=$(addprefix $(MINERVA_SHARE_DIR)/,$(wildcard migrations/*.sql))

DIRS=\
	$(BIN_DIR) \
	$(MINERVA_SHARE_DIR) \
	$(MINERVA_SHARE_DIR)/src \
	$(MINERVA_SHARE_DIR)/migrations

all:

clean:

install:\
	$(DIRS) \
	$(SRC_FILES) \
	$(MIGRATION_FILES) \
	$(SCRIPT_FILES)


$(DIRS):
	mkdir -p $@

$(SRC_FILES): src/$(@F) | $(MINERVA_SHARE_DIR)
	install -m 0644 "src/$(@F)" "$(@)"

$(MIGRATION_FILES): migrations/$(@F) | $(MINERVA_SHARE_DIR)
	install -m 0644 "migrations/$(@F)" "$(@)"

$(SCRIPT_FILES): bin/$(@F) | $(BIN_DIR)
	install -m 0755 "bin/$(@F)" "$(@)"
