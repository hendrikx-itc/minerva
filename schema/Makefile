#!/usr/bin/make
.SECONDEXPANSION:

BIN_DIR=$(DESTDIR)/usr/bin
MINERVA_SHARE_DIR=$(DESTDIR)/usr/share/minerva

SCRIPTS=$(addprefix $(BIN_DIR)/,init-minerva-db)
SQL_SCRIPTS=$(addprefix $(MINERVA_SHARE_DIR)/,$(patsubst scripts/%,%,$(wildcard scripts/*.sql)))
SQL_SCRIPTS_PUBLIC=$(addprefix $(MINERVA_SHARE_DIR)/,$(patsubst scripts/%,%,$(wildcard scripts/10_public/*.sql)))
SQL_SCRIPTS_DIRECTORY=$(addprefix $(MINERVA_SHARE_DIR)/,$(patsubst scripts/%,%,$(wildcard scripts/30_directory/*.sql)))
SQL_SCRIPTS_SYSTEM=$(addprefix $(MINERVA_SHARE_DIR)/,$(patsubst scripts/%,%,$(wildcard scripts/20_system/*.sql)))
SQL_SCRIPTS_RELATION=$(addprefix $(MINERVA_SHARE_DIR)/,$(patsubst scripts/%,%,$(wildcard scripts/40_relation/*.sql)))
SQL_SCRIPTS_DIMENSION=$(addprefix $(MINERVA_SHARE_DIR)/,$(patsubst scripts/%,%,$(wildcard scripts/15_dimension/*.sql)))
SQL_SCRIPTS_STORAGE_TREND=$(addprefix $(MINERVA_SHARE_DIR)/,$(patsubst scripts/%,%,$(wildcard scripts/50_storage/trend/*.sql)))
SQL_SCRIPTS_STORAGE_ATTRIBUTE=$(addprefix $(MINERVA_SHARE_DIR)/,$(patsubst scripts/%,%,$(wildcard scripts/50_storage/attribute/*.sql)))
SQL_SCRIPTS_STORAGE_GEOSPATIAL=$(addprefix $(MINERVA_SHARE_DIR)/,$(patsubst scripts/%,%,$(wildcard scripts/50_storage/geospatial/*)))
SQL_SCRIPTS_STORAGE_NOTIFICATION=$(addprefix $(MINERVA_SHARE_DIR)/,$(patsubst scripts/%,%,$(wildcard scripts/50_storage/notification/*.sql)))

DIRS=\
	 $(BIN_DIR) \
	 $(MINERVA_SHARE_DIR) \
	 $(MINERVA_SHARE_DIR)/10_public \
	 $(MINERVA_SHARE_DIR)/15_dimension \
	 $(MINERVA_SHARE_DIR)/30_directory \
	 $(MINERVA_SHARE_DIR)/20_system \
	 $(MINERVA_SHARE_DIR)/40_relation \
	 $(MINERVA_SHARE_DIR)/50_storage/trend \
	 $(MINERVA_SHARE_DIR)/50_storage/attribute \
	 $(MINERVA_SHARE_DIR)/50_storage/geospatial \
	 $(MINERVA_SHARE_DIR)/50_storage/notification \
	 $(MINERVA_SHARE_DIR)/extensions

all:

clean:

install:\
	$(DIRS) \
	$(SQL_SCRIPTS) \
	$(SQL_SCRIPTS_PUBLIC) \
	$(SQL_SCRIPTS_DIRECTORY) \
	$(SQL_SCRIPTS_SYSTEM) \
	$(SQL_SCRIPTS_RELATION) \
	$(SQL_SCRIPTS_DIMENSION) \
	$(SQL_SCRIPTS_STORAGE_TREND) \
	$(SQL_SCRIPTS_STORAGE_ATTRIBUTE) \
	$(SQL_SCRIPTS_STORAGE_GEOSPATIAL) \
	$(SQL_SCRIPTS_STORAGE_NOTIFICATION) \
	$(SCRIPTS) \
	$(CONF_FILES)


$(DIRS):
	mkdir -p $@

$(SCRIPTS): $$(@F)
	install -m 0755 $(@F) $(@)

$(CONF_FILES): $$(@F)
	install -m 0600 $(@F) $(@)

$(SQL_SCRIPTS): scripts/$$(@F) | $(MINERVA_SHARE_DIR)
	install -m 0644 scripts/$(@F) $(@)

$(SQL_SCRIPTS_PUBLIC): scripts/10_public/$$(@F) | $(MINERVA_SHARE_DIR)/10_public
	install -m 0644 scripts/10_public/$(@F) $(@)

$(SQL_SCRIPTS_DIRECTORY): scripts/30_directory/$$(@F) | $(MINERVA_SHARE_DIR)/30_directory
	install -m 0644 scripts/30_directory/$(@F) $(@)

$(SQL_SCRIPTS_SYSTEM): scripts/20_system/$$(@F) | $(MINERVA_SHARE_DIR)/20_system
	install -m 0644 scripts/20_system/$(@F) $(@)

$(SQL_SCRIPTS_RELATION): scripts/40_relation/$$(@F) | $(MINERVA_SHARE_DIR)/40_relation
	install -m 0644 scripts/40_relation/$(@F) $(@)

$(SQL_SCRIPTS_DIMENSION): scripts/15_dimension/$$(@F) | $(MINERVA_SHARE_DIR)/15_dimension
	install -m 0644 scripts/15_dimension/$(@F) $(@)

$(SQL_SCRIPTS_STORAGE_TREND): scripts/50_storage/trend/$$(@F) | $(MINERVA_SHARE_DIR)/50_storage/trend
	install -m 0644 scripts/50_storage/trend/$(@F) $(@)

$(SQL_SCRIPTS_STORAGE_ATTRIBUTE): scripts/50_storage/attribute/$$(@F) | $(MINERVA_SHARE_DIR)/50_storage/attribute
	install -m 0644 scripts/50_storage/attribute/$(@F) $(@)

$(SQL_SCRIPTS_STORAGE_GEOSPATIAL): scripts/50_storage/geospatial/$$(@F) | $(MINERVA_SHARE_DIR)/50_storage/geospatial
	install -m 0644 scripts/50_storage/geospatial/$(@F) $(@)

$(SQL_SCRIPTS_STORAGE_NOTIFICATION): scripts/50_storage/notification/$$(@F) | $(MINERVA_SHARE_DIR)/50_storage/notification
	install -m 0644 scripts/50_storage/notification/$(@F) $(@)
