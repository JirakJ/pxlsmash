PREFIX ?= /usr/local
VERSION := $(shell git describe --tags --always 2>/dev/null || echo "dev")

.PHONY: build release install uninstall test clean universal

build:
	swift build -c debug

release:
	swift build -c release

universal:
	swift build -c release --arch arm64 --arch x86_64
	@echo "Universal binary: .build/apple/Products/Release/pxlsmash"
	@lipo -info .build/apple/Products/Release/pxlsmash

install: release
	install -d $(PREFIX)/bin
	install .build/release/pxlsmash $(PREFIX)/bin/pxlsmash
	install -d $(PREFIX)/share/man/man1
	install -m 644 docs/pxlsmash.1 $(PREFIX)/share/man/man1/pxlsmash.1
	@echo "Installed pxlsmash to $(PREFIX)/bin/pxlsmash"

uninstall:
	rm -f $(PREFIX)/bin/pxlsmash
	@echo "Uninstalled pxlsmash"

test:
	swift test

clean:
	swift package clean
	rm -rf .build dist

dist: universal
	mkdir -p dist
	cp .build/apple/Products/Release/pxlsmash dist/
	cd dist && tar -czf pxlsmash-$(VERSION)-macos-universal.tar.gz pxlsmash
	cd dist && zip -j pxlsmash-$(VERSION)-macos-universal.zip pxlsmash
	cd dist && shasum -a 256 pxlsmash-$(VERSION)-macos-universal.tar.gz > pxlsmash-$(VERSION)-macos-universal.tar.gz.sha256
	cd dist && shasum -a 256 pxlsmash-$(VERSION)-macos-universal.zip > pxlsmash-$(VERSION)-macos-universal.zip.sha256
	@echo "Distribution archives: dist/pxlsmash-$(VERSION)-macos-universal.{tar.gz,zip}"
