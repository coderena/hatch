SRC=src
OUT=out
DEP=.dep

CONTENT_PATH=$(SRC)/contents
CONTENT_OUT_PATH=$(subst $(SRC),$(OUT), $(CONTENT_PATH))
CONTENT_DEP_PATH=$(subst $(SRC),$(DEP), $(CONTENT_PATH))
OUT_PATHS=$(subst $(SRC),$(OUT), $(shell find $(CONTENT_PATH) -type d -name '*'))

CONTENT_DEP_PATHS=$(subst $(SRC),$(DEP),$(shell find $(CONTENT_PATH) -type d -name '*'))
CONTENT_DEPS=$(subst $(SRC),$(DEP),$(shell find $(CONTENT_PATH) -type f -name '*'))

LAYOUT_PATH=$(SRC)/layouts
LAYOUT_DEP_PATH=$(subst $(SRC),$(DEP),$(LAYOUT_PATH))
LAYOUT_DEP_PATHS=$(subst $(SRC),$(DEP),$(shell find $(LAYOUT_PATH) -type d -name '*'))
LAYOUTS=$(shell find $(LAYOUT_PATH) -type f -name '*')
LAYOUT_DEPS=$(subst $(SRC),$(DEP),$(LAYOUTS))

HATCH_PARSE = ./hatch/scripts/hatch-parse.coffee
HATCH_GEN = ./hatch/scripts/hatch-gen.coffee
HATCH_DIFF = ./hatch/scripts/hatch-diff.coffee
HATCH_CLEAN = ./hatch/scripts/hatch-clean.coffee

.PHONY: all parse content_depend layout_depend clean fullclean

all: layout_depend parse generate content_depend
	@echo "Build completed!"

# parsing the docouments into database
parse:
	@echo "Parsing the documents into database."
	@$(HATCH_PARSE) $(shell $(HATCH_DIFF) $(CONTENT_PATH) $(CONTENT_DEP_PATH))
# parsing done


# generating the target documents
$(OUT_PATHS): $(OUT)%: $(SRC)%
	@echo "Creating output paths."
	@mkdir -p $@

generate: $(OUT_PATHS)
	@echo "Generate documents."
	@$(HATCH_GEN) $(shell $(HATCH_DIFF) -e .html $(CONTENT_PATH) $(CONTENT_OUT_PATH))

# generating done

# creating dependencies
$(LAYOUT_DEP_PATHS) $(CONTENT_DEP_PATHS): $(DEP)%: $(SRC)%
	@echo "Creating dependency paths $@."
	@mkdir -p $@

$(CONTENT_DEPS): $(DEP)/%: $(SRC)/%
	@touch $@

$(LAYOUT_DEPS): $(LAYOUTS)
	@$(HATCH_CLEAN) $(shell $(HATCH_DIFF) $(LAYOUT_PATH) $(LAYOUT_DEP_PATHS))
	@touch $(LAYOUT_DEPS)

content_depend: $(CONTENT_DEP_PATHS) $(CONTENT_DEPS)

layout_depend: $(LAYOUT_DEP_PATHS) $(LAYOUT_DEPS)
# dependency done

# clean utility
clean:
	@rm -rf $(DEP)
	@rm -rf $(OUT)

fullclean: clean
	@mongo hatch --quiet --eval "db.documents.remove()"
# clean done

# misc
test:
	@echo "
diff:
	@echo "Comparing $(CONTENT_PATH) with $(OUT_PATH):"
	@echo $(shell $(HATCH_DIFF) -e .html $(CONTENT_PATH) $(OUT_PATH))
	@echo "\nComparing $(SRC) with $(DEP):"
	@echo $(shell $(HATCH_DIFF) $(SRC) $(DEP))
