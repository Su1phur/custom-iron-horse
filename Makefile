# Various needed programs
GIT = git
PYTHON3 = python3
SED = sed
ZIP = zip

NMLC = nmlc
GRFCODEC = grfcodec
GRFID = grfid

GIT_INFO = $(PYTHON3) src/polar_fox/git_info.py
FILL_TEMPLATE = bin/fill-template
FIND_FILES = bin/find-files
MK_ARCHIVE = bin/mk-archive


# Project details
PROJECT_NAME = iron-horse

GRAPHICS_TARGET = generated/graphics/make_target
NML_TARGET = generated/nml/make_target
LANG_DIR_BASE = generated/lang
LANG_TARGET = $(LANG_DIR_BASE)/english.lng

-include Makefile.local

EXPORTED = no
ifeq ($(strip $(EXPORTED)),no)
  # Not exported source, therefore regular checkout
  REPO_INFO = $(shell $(GIT_INFO))
  REPO_REVISION = $(word 1,$(REPO_INFO))
  REPO_VERSION = $(word 2,$(REPO_INFO))
else
  # Exported version, lines below should get modified in 'bundle_src' target
  REPO_REVISION = ${exported_revision}
  REPO_VERSION = ${exported_version}
endif

REPO_TITLE = "$(PROJECT_NAME) $(REPO_VERSION)"
PROJECT_VERSIONED_NAME = $(PROJECT_NAME)-$(REPO_VERSION)
# optional make args that will be passed through to python
ifdef GRF
  GRF_NAMES = iron-$(GRF)
else
  GRF_NAMES = iron-horse iron-moose
  GRF = 'ALL'
endif
ifdef PW
    pool-workers = --pool_workers=$(PW)
endif
ifeq ($(SC), True)
  suppress-cargo-sprites = --suppress-cargo-sprites
endif
ifeq ($(SD), True)
  suppress-docs = --suppress-docs
endif
# --grf-name needs to be handled differently depending on the python script, so is not included in PY_GLOBAL_ARGS
PY_GLOBAL_ARGS = $(pool-workers) $(suppress-cargo-sprites) $(suppress-docs)

# GRF_FILES include the full path to generated dir and .grf suffixes
GRF_FILES = $(GRF_NAMES:%=generated/%.grf)
NFO_FILES = $(GRF_FILES:.grf=.nfo)
NML_FILES = $(GRF_FILES:.grf=.nml)
LANG_FILES = $(GRF_NAMES:%=generated/lang/%/english.lng)
TAR_FILE = $(PROJECT_VERSIONED_NAME).tar
ZIP_FILE = $(PROJECT_VERSIONED_NAME).zip
MD5_FILE = $(PROJECT_NAME).check.md5
HTML_DOCS = $(GRF_NAMES:%=docs/%/index.html)

SOURCE_NAME = $(PROJECT_VERSIONED_NAME)-source
BUNDLE_DIR = bundle_dir

# Build rules
.PHONY: default graphics lang nml grf tar bundle_tar bundle_zip bundle_src clean
default: html_docs grf
# bundle needs to clean first to ensure we don't use outdated/cached version info
bundle_tar: clean tar
bundle_zip: $(ZIP_FILE)
release: bundle_tar copy_docs_to_grf_farm
graphics: $(GRAPHICS_TARGET)
lang: $(LANG_TARGET)
nml: $(NML_FILES)
nfo: $(NFO_FILES)
grf: $(GRF_FILES)
tar: $(TAR_FILE)
html_docs: $(HTML_DOCS)

# default num. pool workers for python compile,
# default is 0 to disable multiprocessing (also avoids multiprocessing pickle failures masking genuine python errors)
PW = 0
# option to suppress cargo sprites, makes minor difference to compile time
SC = 'False'
# remove the @ for more verbose output (@ suppresses command output)
_V ?= @

$(GRAPHICS_TARGET): $(shell $(FIND_FILES) --ext=.py --ext=.png src)
	$(_V) $(PYTHON3) src/render_graphics.py $(PY_GLOBAL_ARGS) --grf-name=iron-horse
	$(_V) touch $(GRAPHICS_TARGET)

$(LANG_FILES): $(shell $(FIND_FILES) --ext=.py --ext=.pynml --ext=.lng src)
	$(_V) $(PYTHON3) src/render_lang.py $(PY_GLOBAL_ARGS) --grf-name=$(subst /english.lng,,$(subst generated/lang/,,$@))

$(HTML_DOCS): $(GRAPHICS_TARGET) $(LANG_FILES) $(shell $(FIND_FILES) --ext=.py --ext=.pynml --ext=.pt --ext=.lng --ext=.png src)
	$(_V) $(PYTHON3) src/render_docs.py $(PY_GLOBAL_ARGS) --grf-name=$(subst /index.html,,$(subst docs/,,$@))

$(NML_FILES): $(shell $(FIND_FILES) --ext=.py --ext=.pynml src)
	$(_V) $(PYTHON3) src/render_nml.py $(PY_GLOBAL_ARGS) --grf-name=$(subst .nml,,$(subst generated/,,$@))

# nmlc is used to compile a nfo file only, which is then used by grfcodec
# this means that the (relatively slow) nmlc stage can be skipped if the nml file is unchanged (only graphics changed)
$(NFO_FILES): %.nfo : %.nml $(LANG_FILES) | $(GRAPHICS_TARGET)
	$(NMLC) -l $(LANG_DIR_BASE)/$(*F) --verbosity=4 --palette=DEFAULT  --no-optimisation-warning --nfo=$@ $<

# N.B grf codec can't compile into a specific target dir, so after compiling, move the compiled grf to appropriate dir
# grfcodec -n was tried, but was slower and produced a large grf file
$(GRF_FILES): %.grf : %.nfo $(GRAPHICS_TARGET)
# we use notdir and dir to get the correct paths from the list of target filenames (which include generated dir)
# result is e.g. grfcodec -s -e -c -g 2 iron-horse.grf generated/
	time $(GRFCODEC) -s -e -c -g 2 $(notdir $@) $(dir $<)
	$(_V) mv $(notdir $@) $@

$(TAR_FILE): $(GRF_FILES) $(HTML_DOCS)
# the goal here is a sparse tar for distribution
	# create an intermediate dir, and copy in what we need
	mkdir $(PROJECT_VERSIONED_NAME)
	cp docs/readme.txt $(PROJECT_VERSIONED_NAME)
	cp docs/changelog.txt $(PROJECT_VERSIONED_NAME)
	cp docs/license.txt $(PROJECT_VERSIONED_NAME)
	cp $(GRF_FILES) $(PROJECT_VERSIONED_NAME)
	$(MK_ARCHIVE) --tar --output=$(TAR_FILE) $(PROJECT_VERSIONED_NAME)
	# delete the intermediate dir
	rm -r $(PROJECT_VERSIONED_NAME)

$(ZIP_FILE): $(TAR_FILE)
	$(ZIP) -9rq $(ZIP_FILE) $(TAR_FILE) >/dev/null

$(MD5_FILE): $(GRF_FILES)
	$(GRFID) -m $(GRF_FILES) > $(MD5_FILE)

bundle_src: $(MD5_FILE)
	if test -d $(BUNDLE_DIR); then rm -r $(BUNDLE_DIR); fi
	mkdir $(BUNDLE_DIR)
	$(GIT) archive -t files $(BUNDLE_DIR)/src
	$(FILL_TEMPLATE) --template=Makefile \
		--output=$(BUNDLE_DIR)/src/Makefile \
		"exported_revision=$(REPO_REVISION)" \
		"exported_version=$(REPO_VERSION)"
	$(SED) -i -e 's/^EXPORTED = no/EXPORTED = yes/' $(BUNDLE_DIR)/src/Makefile
	$(MK_ARCHIVE) --tar --output=$(SOURCE_NAME).tar --base=$(SOURCE_NAME) \
		`$(FIND_FILES) $(BUNDLE_DIR)/src` $(MD5_FILE)

# this expects to find a '../../grf.farm' path relative to the project, and will fail otherwise
copy_docs_to_grf_farm:
	$(_V) $(PYTHON3) src/polar_fox/grf_farm.py $(PROJECT_NAME)

# this is a macOS-specifc install location; the pre-2017 Makefile handled multiple platforms, that could be restored if needed
# remove first, OpenTTD does not like having the _contents_ of the current file change under it, but will handle a removed-and-replaced file correctly
install: default
# note the switch to shell syntax for vars in the for loop, rather than make syntax;
# also the bash magic to strip directory from GRF_FILE_PATH
	$(_V) echo "[INSTALLING]"
	$(_V) for GRF_NAME in $(GRF_NAMES) ; do \
		echo .. $$GRF_NAME ; \
		rm ~/Documents/OpenTTD/newgrf/$${GRF_NAME}.grf ; \
		cp generated/$$GRF_NAME.grf ~/Documents/OpenTTD/newgrf/ ; \
	done
	$(_V) echo "[DONE]"


clean:
	$(_V) echo "[CLEANING]"
	$(_V) for f in .chameleon_cache .nmlcache src/__pycache__ src/*/__pycache__ docs generated \
	$(GRF_FILES) $(TAR_FILE) $(ZIP_FILE) $(MD5_FILE) $(BUNDLE_DIR) $(SOURCE_NAME).tar;\
	do if test -e $$f;\
	   then rm -r $$f;\
	   fi;\
	done
	$(_V) echo "[DONE]"
