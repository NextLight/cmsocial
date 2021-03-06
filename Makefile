DEST=cmsocial-web.build
MAKEROOT=$(shell pwd)
SHELL := /bin/bash

PROD ?= 0
ONLINE ?= $(PROD)

ifeq ($(ONLINE), 1)
CDNFLAGS=
else
CDNFLAGS=--use-local
endif

ifeq ($(PROD), 1)
STRIPDEBUG=sed '/<!-- *start  *debug *-->/,/<!-- *end  *debug *-->/d'
UGLIFY=node_modules/.bin/uglifyjs -c --
else
STRIPDEBUG=cat
UGLIFY=cat
endif

WEBDIRS=$(shell find cmsocial-web -type d)
TMPDIRS=$(patsubst cmsocial-web%,tmp%,$(WEBDIRS))
DESTDIRS=$(patsubst cmsocial-web%,$(DEST)%,$(WEBDIRS))

JS=$(shell find cmsocial-web -type f -name '*.js' | sort)
LESS=$(shell find cmsocial-web -type f -name '*.less')
HTML=$(shell find cmsocial-web -type f -name '*.html')
DESTHTML=$(patsubst cmsocial-web/%,$(DEST)/%,$(HTML))
CSS=$(patsubst cmsocial-web/%.less,tmp/%.css,$(LESS))
TMPJS=$(patsubst cmsocial-web/%.js,tmp/%.js,$(JS))

.PHONY: all dirs other-files config-files js-deps clean distclean

all: $(DESTHTML) $(DEST)/styles/main.css $(DEST)/scripts/app.processed.js js-deps other-files config-files | dirs

other-files: $(DEST)/robots.txt $(DEST)/images/loader.gif $(DEST)/__init__.py

config-files: $(DEST)/custom_images $(DEST)/favicon.ico $(DEST)/views/footer.html $(DEST)/views/homepage.html

ifeq ($(ONLINE), 1)
js-deps:
else
js-deps: $(DEST)/node_modules
endif

config/%: | config/%.sample
	cp $| $@

node_modules: package.json
	npm install
	touch node_modules

dirs: $(DEST) tmp

$(DEST): cmsocial-web
	mkdir -p $(DESTDIRS)
	touch $(DEST)

tmp: cmsocial-web
	mkdir -p $(TMPDIRS)
	touch tmp

$(DEST)/custom_images: config/custom_images | $(DEST)
	cp -r $^ $@

$(DEST)/favicon.ico: config/favicon.ico | $(DEST)
	cp $^ $@

$(DEST)/views/footer.html: config/footer.html | $(DEST)
	cp $^ $@

$(DEST)/views/homepage.html: config/homepage.html | $(DEST)
	cp $^ $@

$(DEST)/index.html: cmsocial-web/index.html node_modules config/cmsocial.ini | $(DEST)
	./instantiate.sh <(node_modules/.bin/cdnify $(CDNFLAGS) $<) | $(STRIPDEBUG) > $@

$(DEST)/%.html: cmsocial-web/%.html config/cmsocial.ini | $(DEST)
	./instantiate.sh $< | $(STRIPDEBUG) > $@

$(DEST)/styles/main.css: $(CSS)
	cat $^ > $@

tmp/%.css: cmsocial-web/%.less node_modules | tmp
	node_modules/.bin/lessc $< $@

$(DEST)/scripts/app.processed.js: $(TMPJS) | node_modules
	${UGLIFY} $^ > $@

tmp/%.js: cmsocial-web/%.js config/cmsocial.ini | tmp
	./instantiate.sh $< | $(STRIPDEBUG) > $@

$(DEST)/node_modules: node_modules
	rsync -av --delete node_modules $(DEST)/
	touch $(DEST)/node_modules

$(DEST)/%: cmsocial-web/%
	cp $^ $@

clean:
	rm -rf tmp/ $(DEST) build/ cmsocial.egg-info/ dist/

distclean: clean
	rm -rf node_modules
