UNAME := $(shell uname)
ARCH := $(patsubst aarch64,arm64,$(shell uname -m))

ifeq ($(UNAME), Linux)
    OS := linux
    EXT := so
else ifeq ($(UNAME), Darwin)
    OS := macOS
    EXT := dylib
else ifeq ($(UNAME), Windows_NT)
    OS := windows
    EXT := dll
else ifneq ($(findstring MSYS_NT,$(UNAME)),)
    OS := windows
    EXT := dll
else
    $(error Unsupported operating system: $(UNAME))
endif

LUA_VERSIONS := luajit lua51
BUILD_DIR := build

.PHONY: test docs all luajit lua51 tiktoken clean

test:
	nvim --headless --clean -u ./scripts/test.lua

PANVIMDOC_DIR ?= .dependencies/panvimdoc

docs:
	@test -d $(PANVIMDOC_DIR) || git clone --depth 1 https://github.com/kdheepak/panvimdoc $(PANVIMDOC_DIR)
	pandoc --metadata=project:MinuetChat --metadata=vimversion:"NVIM v0.10.0" \
		--metadata=toc:true --metadata=description:"" --metadata=titledatepattern:"%Y %B %d" \
		--metadata=dedupsubheadings:true --metadata=ignorerawblocks:true --metadata=docmapping:false \
		--metadata=docmappingproject:true --metadata=treesitter:true --metadata=incrementheadinglevelby:0 \
		--lua-filter $(PANVIMDOC_DIR)/scripts/include-files.lua \
		--lua-filter $(PANVIMDOC_DIR)/scripts/skip-blocks.lua \
		-t $(PANVIMDOC_DIR)/scripts/panvimdoc.lua README.md -o doc/MinuetChat.txt

all: luajit

luajit: $(BUILD_DIR)/tiktoken_core.$(EXT)
lua51: $(BUILD_DIR)/tiktoken_core-lua51.$(EXT)


define download_release
	curl -LSsf https://github.com/gptlang/lua-tiktoken/releases/latest/download/tiktoken_core-$(1)-$(2)-$(3).$(EXT) -o $(4)
endef

$(BUILD_DIR)/tiktoken_core.$(EXT): | $(BUILD_DIR)
	$(call download_release,$(OS),$(ARCH),luajit,$@)

$(BUILD_DIR)/tiktoken_core-lua51.$(EXT): | $(BUILD_DIR)
	$(call download_release,$(OS),$(ARCH),lua51,$@)

tiktoken: $(BUILD_DIR)/tiktoken_core.$(EXT) $(BUILD_DIR)/tiktoken_core-lua51.$(EXT)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
