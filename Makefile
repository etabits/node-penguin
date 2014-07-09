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



node_modules/express:
	npm install express@~4.5.1 mongoose@~3.8.12

example-run: node_modules/express
	cd example/ && coffee seed.coffee && supervisor -e 'jade|coffee|js|json' -i ../views -w ../ -x coffee -n error -- server.coffee
