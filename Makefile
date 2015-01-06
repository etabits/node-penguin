-include /files/projects/common/libs.mk

STATICS_PATH = ./statics

JQUERY_EXCLUDE=
JQUERY_OUTPUT = $(STATICS_PATH)/js/10-jquery.js

BOOTSTRAP_COMPONENTS = .+
BOOTSTRAP_OUTPUT = $(STATICS_PATH)/css/10-bootstrap.css

BOOTSTRAP_JS = .+
BOOTSTRAP_JS_OUTPUT = $(STATICS_PATH)/js/20-bootstrap.js

#FLATUI_COMPONENTS = $(BOOTSTRAP_COMPONENTS)
FLATUI_OUTPUT = $(STATICS_PATH)/css/20-flatui.css
FLATUI_JS_OUTPUT = $(STATICS_PATH)/js/00-all.js



node_modules/express:
	ln -s ../example/node_modules/express	node_modules/express
	ln -s ../example/node_modules/mongoose	node_modules/mongoose

example-flash-messages-enable:
	cd example/ && npm install connect-flash cookie-parser express-session
example-flash-messages-disable:
	bash -c 'rm -r example/node_modules/{connect-flash,cookie-parser,express-session}'


example-run: node_modules/express
	-rm -fr example/uploads
	cd example/ && npm install && coffee seed.coffee && supervisor -e 'jade|coffee|js|json' -i ../views,../statics -w ../ -x coffee -n error -- server.coffee

download-libs:
	wget -O statics/js/30-moment.js http://momentjs.com/downloads/moment.js
	wget -O statics/js/31-combodate.js https://raw.githubusercontent.com/vitalets/combodate/master/combodate.js


compress:
	./scripts/compress.sh