widgets = {}

toHTML = (name, f)->
	value = f.value
	if f.value instanceof Date
		value = f.value.toISOString().substr(0, 19)
	"<input type=\"#{this.type}\" id=\"id_#{name}\" name=\"#{name}\" value=\"#{value}\" />"

widgets.datetime =  (opt={})->
	{ classes: opt.classes, type: 'datetime', toHTML: toHTML }


module.exports = widgets