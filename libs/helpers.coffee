os = require 'os'
fs = require 'fs'
path = require 'path'
AdmZip = require 'adm-zip'
request = require 'request'
Promise = require 'promise'

module.exports = self =
	getDirectory: ->
		if os.platform() == "linux"
			return path.join process.env.HOME, "/.minecraft"
		if os.platform() is "win32" or "win64"
			return path.join process.env.APPDATA, "/.minecraft"
		if os.platform() is "darwin"
			return path.join process.env.HOME, "/Library/Application Support/minecraft"
	getLauncherProfiles: ->
		profilePath = self.getDirectory()
		profilePath = path.join profilePath, 'launcher_profiles.json'
		JSON.parse(fs.readFileSync(profilePath))
	saveLauncherProfiles: (file) ->
		data = JSON.stringify(file)
		profilePath = self.getDirectory()
		profilePath = path.join profilePath, 'launcher_profiles.json'
		fs.writeFileSync(profilePath,data)
	loadProfile: (name)->
		profiles = self.getLauncherProfiles().profiles
		profiles[name]
	saveProfile: (name, profile) ->
		file = self.getLauncherProfiles()
		file.profiles[name]=profile
		self.saveLauncherProfiles(file)
	getAllPacks: () ->
		dir = path.join self.getDirectory() + '/modpacks/'
		packs = fs.readdirSync(dir)
		return packs
	listProfiles: ->
		profiles = self.getLauncherProfiles().profiles
		Object.keys(profiles)
	fetchJson: (url) ->
		return new Promise (fufill, reject) ->
			request url, (err,_,body) ->
				if err
					reject err
					return
				fufill JSON.parse body
	getModInfo: (file) ->
		try
			zip = new AdmZip file
		catch
			return false
		zipEntries = zip.getEntries()
		infoFile = zip.getEntry 'mcmod.info'
		if not infoFile
			return false
		info = JSON.parse(infoFile.getData().toString().replace(/(\r\n|\n|\r)/gm,""))
		if info.length
			info = info[0]
		return info
	getModList: (dir) ->
		dir = path.join dir, 'mods'
		mods = []
		modDir = fs.readdirSync(dir)
		for item in modDir
			stat = fs.statSync path.join dir, item
			if stat.isFile()
				info = self.getModInfo path.join dir, item
				if not info
					info = {}
				info.file = item
				if not info.name
					info.name = item.replace(/\.[^/.]+$/, "")
				mods.push(info)
		return mods
	downloadFile: (dir, url, file, log, progress) ->
		return new Promise (resolve, reject) ->
			log "starting download "+file
			request
				.get url
				.on 'response', ->
					log "Finished downloading "+file
					progress()
					resolve()
				.on 'error', (err) ->
					reject(err)
				.pipe fs.createWriteStream path.join dir, file
