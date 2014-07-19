-include /files/projects/common/libs.mk

STATICS_PATH = ./statics

JQUERY_EXCLUDE=
JQUERY_OUTPUT = $(STATICS_PATH)/10-jquery.js

BOOTSTRAP_COMPONENTS = .+
BOOTSTRAP_OUTPUT = $(STATICS_PATH)/10-bootstrap.css

BOOTSTRAP_JS = .+
BOOTSTRAP_JS_OUTPUT = $(STATICS_PATH)/20-bootstrap.js

#FLATUI_COMPONENTS = $(BOOTSTRAP_COMPONENTS)
FLATUI_OUTPUT = $(STATICS_PATH)/20-flatui.css
FLATUI_JS_OUTPUT = $(STATICS_PATH)/00-all.js


node_modules/express:
	ln -s ../example/node_modules/express	node_modules/express
	ln -s ../example/node_modules/mongoose	node_modules/mongoose

example-run: node_modules/express
	cd example/ && npm install && coffee seed.coffee && supervisor -e 'jade|coffee|js|json' -i ../views -w ../ -x coffee -n error -- server.coffee
