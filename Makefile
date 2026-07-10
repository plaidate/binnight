# Bin Night - a tag-team trash heist for Playdate.
#
#   make            release build -> out/BinNight.pdx
#   make smoke      instrumented build -> out/BinNightSmoke.pdx
#
# Staging copies source/* into build/<variant>/source and writes
# smokeflag.lua (pdc wants one source root; smokeflag is generated).

OUT := out

all: release

release: build/release/source
	pdc build/release/source $(OUT)/BinNight.pdx

smoke: build/smoke/source
	pdc build/smoke/source $(OUT)/BinNightSmoke.pdx

build/release/source: source/*
	mkdir -p $@ $(OUT)
	cp -r source/* $@/
	echo 'SMOKE_BUILD = false' > $@/smokeflag.lua

build/smoke/source: source/*
	mkdir -p $@ $(OUT)
	cp -r source/* $@/
	echo 'SMOKE_BUILD = true' > $@/smokeflag.lua

clean:
	rm -rf build $(OUT)

.PHONY: all release smoke clean
