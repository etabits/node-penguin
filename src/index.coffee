fs = require 'fs'
path = require 'path'

express = require 'express'
merge = require 'merge'


forms = require('forms')
fields = forms.fields
validators = forms.validators
widgets = forms.widgets

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
			self.models = models
			for name, model of models
				#console.log name, model

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
				"#{@opts.staticsPath}/10-bootstrap.css"
				"#{@opts.staticsPath}/20-flatui.css"
				"#{@opts.staticsPath}/50-penguin.css"
			]
			js: [
				"#{@opts.staticsPath}/10-jquery.js"
				"#{@opts.staticsPath}/20-bootstrap.js"
				"#{@opts.staticsPath}/90-penguin.js"
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
			formFields[name] = fields[fieldOpts.type] {
				widget: widgets[fieldOpts.widget]()
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
		req.model.obj.findById req.params.id, (err, doc)->

			req.row = doc
			return next()
		return



	# ROUTES
	setupRoutes: =>
		@router.route('/')
			.get			@rIndex					# INDEX

		@router.route('/:collection')
			.get			@rCollection			# LIST
			.put			@rNotImplemented		# CREATE

		
		@router.route('/:collection/:id')
			.get			@rEdit					# EDIT
			.post			@rEdit					# UPDATE
			.delete			@rNotImplemented		# DELETE

	rIndex: (req, res)=>
		self._render req, res, 'index', {title: @opts.indexTitle}
		#return res.send 'hello!'

	rCollection: (req, res)=>
		conditions = req.model.conditions
		#console.log 'Conditions:', req.model.conditions
		#console.log req.model.fieldsToPopulate
		req.model.obj.find(conditions).populate(req.model.fieldsToPopulate.join(' ')).exec (err, docs)->
			console.log('ERR', err) if err
			self._render req, res, 'collection', {
				docs:	docs
				title:	req.model.label 
			}

	rNotImplemented: (req, res)=>
		return res.send('Not Implemented')

	_render: (req, res, template, locals) =>
		res.render path.resolve(__dirname, '../views/', template), locals

	rEdit: (req, res)->
		form = req.model.form
		#console.log 'Row: ', req.row
		renderObj = {
			formOpts: {}
		}
		form.handle req, {
			success: (nform)->

				req.row[k]=v for k,v of nform.data

				req.row.save (err, doc)->
					if err
						renderObj.form = nform
						for fdName, error of err.errors
							#console.log fdName, error
							renderObj.form.fields[fdName].error = error.message
						self._render req, res, 'edit', renderObj
					else
						res.redirect './'


			error: (nform)->
				renderObj.form = nform
				self._render req, res, 'edit', renderObj

			empty: ()->
				#console.log req.row
				
				renderObj.form = form.bind(req.row)
				self._render req, res, 'edit', renderObj

		}



module.exports = {
	Admin: Admin
}