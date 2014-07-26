async = require 'async'

widget = (opt={})->
	w = {
		classes: opt.classes
		type: 'file'
	}
	w.toHTML = (name, f)->
		html = "<input type=\"file\" name=\"#{name}\" />"

		return html

	return w

File = require './modelFile'
fileUploader = (fileObject, done)->
	#console.log fileObject
	f = new File {
		name: 			fileObject.name
		originalName:	fileObject.originalname
		path:			fileObject.path
		extension:		fileObject.extension
		mimeType:		fileObject.mimetype
		size:			fileObject.size
		source: {
			# FIXME we are saving the collection, not the model name.
			model: fileObject.collection
			field: fileObject.fieldname
		}

	}
	f.save (err, savedDoc)->
		done(err, savedDoc)
	#done(null, fileObject.size)


prepareFilesMiddleware = (req, res, next)->
	#console.log 'req.files', req.files
	files = (obj for name, obj of req.files)
	obj.collection = req.params.collection for obj in files
	#return console.log 'Files:', files, '.'
	async.map files, fileUploader, (err, results)->
		for r in results
			#console.log 'Processed File:', r
			req.body[r.source.field] = r._id.toString()
		#console.log req.body
		next()

	#return res.send 'WIP'

module.exports = {
	widget: widget
	prepareFilesMiddleware: prepareFilesMiddleware
}