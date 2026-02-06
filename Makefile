PREFIX ?= /usr/local
VERSION := $(shell git describe --tags --always 2>/dev/null || echo "dev")

.PHONY: build release install uninstall test clean universal

build:
	swift build -c debug

release:
	swift build -c release

universal:
	swift build -c release --arch arm64 --arch x86_64
	@echo "Universal binary: .build/apple/Products/Release/imgcrush"
	@lipo -info .build/apple/Products/Release/imgcrush

install: release
	install -d $(PREFIX)/bin
	install .build/release/imgcrush $(PREFIX)/bin/imgcrush
	@echo "Installed imgcrush to $(PREFIX)/bin/imgcrush"

uninstall:
	rm -f $(PREFIX)/bin/imgcrush
	@echo "Uninstalled imgcrush"

test:
	swift test

clean:
	swift package clean
	rm -rf .build dist

dist: universal
	mkdir -p dist
	cp .build/apple/Products/Release/imgcrush dist/
	cd dist && tar -czf imgcrush-$(VERSION)-macos-universal.tar.gz imgcrush
	cd dist && shasum -a 256 imgcrush-$(VERSION)-macos-universal.tar.gz > imgcrush-$(VERSION)-macos-universal.tar.gz.sha256
	@echo "Distribution archive: dist/imgcrush-$(VERSION)-macos-universal.tar.gz"
