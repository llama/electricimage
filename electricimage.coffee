@Images = new Meteor.Collection("images")

if Meteor.isClient
	Meteor.startup ->
		Session.set('myHashes',[])

	Template.main.myImages = ->
		mh = Session.get('myHashes') or []
		mine = Images.find({hash:{$in: mh}})

		missingHashes = []
		for h in mh
			unless Images.findOne({hash:h})
				missingHashes.push {missingHash:h}

		return mine.fetch().concat(missingHashes)


	addResolutionToDropzonePreview = (file) ->
		setTimeout( (()->
			sizeStr = file.width + ' x ' + file.height
			$(file.previewTemplate).find('.dz-size').text(sizeStr)
			), 10)
			
	Dropzone.options.imgDropzone =
		maxFilesize: 2 # MB
		# maxFiles: 1
		# addRemoveLinks: true
		init: ->
			@on 'success', (file, response) ->
				# if response then console.log 'hash from server: ' + response 
			@on 'error', (f,error) ->
				toastr['warning'](error, 'Error')
				# alert error
		thumbnail: (file,dataUri) ->
			addResolutionToDropzonePreview file
			@defaultOptions.thumbnail file,dataUri
		accept: (file,done) ->
			# fr = new FileReader()
			# fr.onloadend = ->
				# console.log 'done loading'
				# console.log SparkMD5.hashBinary(@result)
			# fr.readAsBinaryString(file)#,'utf-8')
			fastFileMd5 file, (hash,err) =>
				mh = Session.get('myHashes')
				existingImage = Images.findOne hash:hash

				if hash in mh
					# image already on session, dont add again
					@removeFile(file)
					done('Image already added.')

				# addResolutionToDropzonePreview file

				if existingImage
					 # image already calculated, dont reupload
					Images.update existingImage._id, {$inc: {'requestCount':1}}
					file.status = Dropzone.SUCCESS
					@emit("success", file, '', '') # update ui

				mh.push hash
				Session.set 'myHashes', mh
				done()



if Meteor.isServer 
	@Images._ensureIndex('hash', {unique: 1, sparse: 1})
	Meteor.startup ->
		collectionApi = new CollectionAPI(
			authToken: '8e271a3f396fe20710a6' # Require this string to be passed in on each request
			apiPath: "collectionapi" # API path prefix
		)

		# Add the collection Images to the API "/images" path
		collectionApi.addCollection(Images, "images", {
			authToken: '8e271a3f396fe20710a6' # Require this string to be passed in on each request
			methods: [ # Allow creating only
				"POST"
			]
			# before: # This methods, if defined, will be called before the POST/GET/PUT/DELETE actions are performed on the collection. If the function returns false the action will be canceled, if you return true the action will take place.
			# POST: `undefined` # function(obj) {return true/false;},
			# GET: `undefined` # function(collectionID, objs) {return true/false;},
			# PUT: `undefined` #function(collectionID, obj, newValues) {return true/false;},
			# DELETE: `undefined` #function(collectionID, obj) {return true/false;}
		})

		# Starts the API server
		collectionApi.start()
