#!/bin/bash
cat statics/css/*.css > statics/style-all.css
java -jar /files/software/yuicompressor-2.4.8.jar statics/style-all.css > statics/style.css
rm statics/style-all.css

coffee -p statics/js/90-penguin.coffee > statics/js/90-penguin.js
cat statics/js/*.js | java -jar /files/software/closure-compiler/compiler.jar > statics/script.js
rm statics/js/90-penguin.js

#jshash=$(sha1sum statics/script.js | cut -c1-40)
#mv statics/script.js statics/$jshash.js