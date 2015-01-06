async = require 'async'
fs = require('fs')
crypto = require('crypto')
sha1sum = (buf)-> crypto.createHash('sha1').update(buf).digest('hex');
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

rawFileUploader = (raw, done)->
	hash = sha1sum(raw)
	path = "uploads/hash/#{hash}.dat"
	async.parallel {
		saveFile: (done)->
			fs.writeFile path, raw, done
		fileObj: (done)->

			f = new File {
				name: 			"base64-#{hash}"
				originalName:	"base64-#{hash}"
				path:			"/#{path}"
				extension:		'dat'
				mimeType:		'x-application/data'
				size:			raw.length
				source: {
					model: ''
					field: ''
				}
			}
			f.save (err, savedDoc)->
				done(err, savedDoc)

	}, (err, results)->
		done(err, results.fileObj)




uploadRawFilesArray = (files, opts, done)->
	async.map files, rawFileUploader, done



fixBase64 = (html, opts, done)->
	files = []
	html2 = html.replace /src="data:([^;]*);base64,([^"]+)"/g, (a, mime, base64)->
		#console.log mime, '!', base64; d()
		counter = files.length
		files[counter] = new Buffer(base64, 'base64')
		return "src=\"data:;x-penguin,#{counter}\""

	uploadRawFilesArray files, opts, (err, results)->
		return done(err, html) if err
		#console.log results

		html = html2.replace /src="data:;x-penguin,(\d+)"/g, (a, number)->
			#console.log number
			"src=\"#{results[number].path}\""
		#console.log html
		done(err, html)

	#console.log files, html

module.exports = {
	widget: widget
	prepareFilesMiddleware: prepareFilesMiddleware
	save: fileUploader
	fixBase64: fixBase64
}