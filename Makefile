PREFIX ?= /usr/local
VERSION := $(shell git describe --tags --always 2>/dev/null || echo "dev")

.PHONY: build release install uninstall test clean universal

build:
	swift build -c debug

release:
	swift build -c release

universal:
	swift build -c release --arch arm64 --arch x86_64
	@echo "Universal binary: .build/apple/Products/Release/optipix"
	@lipo -info .build/apple/Products/Release/optipix

install: release
	install -d $(PREFIX)/bin
	install .build/release/optipix $(PREFIX)/bin/optipix
	install -d $(PREFIX)/share/man/man1
	install -m 644 docs/optipix.1 $(PREFIX)/share/man/man1/optipix.1
	@echo "Installed optipix to $(PREFIX)/bin/optipix"

uninstall:
	rm -f $(PREFIX)/bin/optipix
	@echo "Uninstalled optipix"

test:
	swift test

clean:
	swift package clean
	rm -rf .build dist

dist: universal
	mkdir -p dist
	cp .build/apple/Products/Release/optipix dist/
	cd dist && tar -czf optipix-$(VERSION)-macos-universal.tar.gz optipix
	cd dist && zip -j optipix-$(VERSION)-macos-universal.zip optipix
	cd dist && shasum -a 256 optipix-$(VERSION)-macos-universal.tar.gz > optipix-$(VERSION)-macos-universal.tar.gz.sha256
	cd dist && shasum -a 256 optipix-$(VERSION)-macos-universal.zip > optipix-$(VERSION)-macos-universal.zip.sha256
	@echo "Distribution archives: dist/optipix-$(VERSION)-macos-universal.{tar.gz,zip}"
