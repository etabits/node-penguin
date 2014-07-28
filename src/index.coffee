fs = require 'fs'
path = require 'path'
querystring = require 'querystring'

express = require 'express'
mongoose = require 'mongoose'
merge = require 'merge'
async = require 'async'
require 'mongoose-query-paginate'

forms = require('forms')
fields = forms.fields
validators = forms.validators
widgets = forms.widgets
merge widgets, require('./widgets')

fileManager = require './fileManager'
widgets.file = fileManager.widget

defaults = require './defaults'

class Admin
	self = null
	constructor: (@opts={}) ->
		self = this
		@opts = merge(defaults.opts, @opts)
		@opts.staticsPath ?= "#{@opts.mountPath}/_statics"
		self.models = {}
		self.modelDetails = {}
		self.resLocals = {
			mountPath: @opts.mountPath
		}
		self._readModels @opts.modelsPath, (err, models)->
			if self.opts.fileManager
				models['files'] = require './modelFile'
			#console.log models
			self.models = models
			for name, model of models
				#self.models[model.modelName] = model

				#continue if .dontInclude
				self.modelDetails[name] = self.getModelDetails {
					base: name
					slug: name
				}

			self.opts.vModels ?= {}
			for vt, vModel of self.opts.vModels
				model = self.models[vModel.base]
				vModel.slug ?= vt

				#console.log vt, vModel


				self.modelDetails[vModel.slug] = self.getModelDetails vModel

			self.resLocals.models = self.modelDetails
			null
		self.resLocals.statics = {
			css: [
				"#{@opts.staticsPath}/css/10-bootstrap.css"
				"#{@opts.staticsPath}/css/20-flatui.css"
				"#{@opts.staticsPath}/css/50-penguin.css"
			]
			js: [
				"#{@opts.staticsPath}/js/10-jquery.js"
				"#{@opts.staticsPath}/js/20-bootstrap.js"
				"#{@opts.staticsPath}/js/90-penguin.js"
			]
		}
		null

	_readModels: (path, done)->
		fs.readdir path, (err, files)->
			return done(err) if err
			models = {}
			for f in files
				model = require "#{path}/#{f}" 
				models[model.collection.name] = model
			return done(null, models)

			



	@_t: (str)->
		str.replace(/([a-z])([A-Z])/g, '$1 $2').replace /(?:^|_)[a-z]/g, (m) -> m.replace(/^_/, ' ').toUpperCase()

	getModelDetails: (vModel)=>
		model = self.models[vModel.base]
		overrides = if vModel.slug == vModel.base then {} else defaults.model$pOverrides
		ret = merge true, defaults.model$p, model.$p, overrides, {
				label:	@constructor._t(vModel.slug)
				path:	"#{self.opts.mountPath}/#{vModel.slug}"
			}, vModel, {
				obj: model
			}
		#console.log vModel.slug, defaults.model$p, model.$p, defaults.model$pOverrides, vModel

		#console.log '>>>', defaults.vModel
		formFields = {}

		model.schema.eachPath (name, details)->
			return if '_' == name.substr(0, 1)
			return if 'undefined'!=typeof ret.conditions[name]
			fieldOpts = self.getDefaultFieldOpts(details)
			#console.log fieldOpts
			return if fieldOpts.hide
			details.$p = fieldOpts
			ret.fields.push(details)
			# Instantiate a new field
			formFields[name] = fields[fieldOpts.type] {
				widget: widgets[fieldOpts.widget]()
				$pField: details
			}
			if 'ObjectID' == details.instance && 'undefined' != typeof details.options.ref
				ret.fieldsToPopulate.push name

		ret.form = forms.create formFields
		ret

	getDefaultFieldOpts: (field)->
		def = defaults.field$p
		fieldOpts = merge true, field.options.$p
		#console.log field.options.type.name
		if not fieldOpts.type && 'undefined' != typeof defaults.typesMap[field.options.type.name]
			def.type = defaults.typesMap[field.options.type.name][0]
			def.widget = defaults.typesMap[field.options.type.name][1]

		if 'ObjectID' == field.instance
			fieldOpts.getRefModel = ()-> self.modelDetails[mongoose.models[field.options.ref].collection.name]
			# Automatically give the file widget for ref:File ObjectId fields
			if 'File' == field.options.ref
				fieldOpts.widget = 'file'

		merge true, def, fieldOpts


	setupApp: (app) =>
		@router = express.Router()
		self = this

		staticsPath = path.resolve(__dirname, '../statics')
		@router.use('/_statics', require('less-middleware')(staticsPath))
		@router.use('/_statics', require('coffee-middleware')({src: staticsPath}))
		@router.use('/_statics', express.static(staticsPath));

		@router.use (req, res, next)->
			for key, val of self.resLocals
				res.locals[key] = val
			next()
		@setupParams()
		@setupRoutes()

		if @opts.preMiddleware
			app.use @opts.mountPath, @opts.preMiddleware
		app.use @opts.mountPath, @router
		app.locals.t = @constructor._t

	# PARAMETERS
	setupParams: =>
		@router.param ':collection', @pCollection
		@router.param ':id', @pId
			
			
		return

	pCollection: (req, res, next)->
		req.model = self.modelDetails[req.params.collection]
		if 'undefined' == typeof req.model
			return res.send(404)

		res.locals.model = self.modelDetails[req.params.collection]
		return next()

	pId: (req, res, next)->
		return res.send(404) if not req.params.id.match /^[0-9a-f]{24}$/
		query = req.model.obj.findById(req.params.id)
		query = query.populate req.model.fieldsToPopulate.join(' ')
		query.exec (err, doc)->

			req.row = doc
			return next()
		return


	getMulterMiddleware: ->
		if not self.multerMiddleware
			multer  = require('multer')
			self.multerMiddleware = multer {
				dest: './uploads/'
				includeEmptyFields: true
			}

		self.multerMiddleware

	# ROUTES
	setupRoutes: =>
		@router.route('/')
			.get			@rIndex					# INDEX

		@router.route('/:collection')
			.get			@rCollection			# LIST
			.put			@rNotImplemented		# CREATE

		
		postMiddlewares = []
		if true
			postMiddlewares.push @getMulterMiddleware()
			postMiddlewares.push fileManager.prepareFilesMiddleware


		@router.route('/:collection/add')
			.get			@rEdit					# Add form
			.post			postMiddlewares, @rEdit	# Add

		@router.route('/:collection/:id')
			.get			@rEdit					# EDIT
			.post			postMiddlewares, @rEdit	# UPDATE
			.delete			@rNotImplemented		# DELETE

	rIndex: (req, res)=>
		self._render req, res, 'index', {title: @opts.indexTitle}
		#return res.send 'hello!'

	rCollection: (req, res)=>
		conditions = merge true, req.model.conditions
		#console.log req.model.fieldsToPopulate
		if req.query.q
			rx = new RegExp(req.query.q, 'i')
			$orConditions = []
			for f in req.model.fields
				continue if 'String'!=f.instance
				#console.log f.instance, f.path
				continue if conditions[f.path]
				c = {}
				c[f.path] = rx
				$orConditions.push c
			if $orConditions.length
				conditions.$or = $orConditions
			#console.log 'or conditions', $orConditions

		#console.log 'Conditions:', conditions, 
		query = req.model.obj.find(conditions)
		#console.log 'fieldsToPopulate', req.model.fieldsToPopulate
		query = query.populate(req.model.fieldsToPopulate.join(' '))
		if req.query.sort
			query = query.sort(req.query.sort)
		paginationOptions = {
			perPage: 25
			delta  : 3
			page   : req.query.p
		}
		query.paginate paginationOptions, (err, result)->
			console.log('ERR', err) if err
			#console.log result.results

			res.locals.getQueryString = (newObj)-> '?'+querystring.stringify merge(true, req.query, newObj)

			self._render req, res, 'collection', {
				docs:	result.results
				title:	req.model.label
				urlQuery:	req.query
				pagination: result
			}

	rNotImplemented: (req, res)=>
		return res.send('Not Implemented')

	_render: (req, res, template, locals) =>
		res.render path.resolve(__dirname, '../views/', template), locals

	rEdit: (req, res)->
		addMode = !req.row
		form = req.model.form
		#console.log form
		#console.log 'Row: ', req.row
		renderObj = {
			formOpts: {}
		}
		#console.log req.body
		form.handle req, {
			success: (nform)->
				if addMode
					req.row = new req.model.obj

				dataToSet = {}
				dataToSet[k]=v for k,v of nform.data

				# Just unset the '' file fields from the data to be set in the row
				for field in req.model.fields
					if 'ObjectID' == field.instance && 'File' == field.options.ref && !dataToSet[field.path]
						delete dataToSet[field.path]

				# Also set the conditions as field values
				if addMode
					dataToSet[k] = v for k, v of req.model.conditions
					#return res.send 'WIP'

				req.row[k]=v for k,v of dataToSet

				#return console.log '111',  nform.data, dataToSet, req.row

				req.row.save (err, doc)->
					#return console.log doc
					if err
						#console.log 'Error', err, err.errors
						renderObj.form = nform
						if err.errors # Need to have a closer look at this...
							for fdName, error of err.errors
								renderObj.form.fields[fdName].error = error.message
						else
							renderObj.form.fields[err.path].error = err.message
						self._render req, res, 'edit', renderObj
					else
						res.redirect './'


			error: (nform)->
				#console.log 'Form Error'
				renderObj.form = nform
				self._render req, res, 'edit', renderObj

			empty: ()->
				#console.log 'Form Empty'
				#console.log req.row
				
				if addMode
					renderObj.form = form
				else
					renderObj.form = form.bind(req.row)
				self._render req, res, 'edit', renderObj

		}



module.exports = {
	Admin: Admin
}