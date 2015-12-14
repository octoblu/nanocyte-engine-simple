DEFAULT_NANOCYTE_NODE_REGISTRY_URL = 'https://raw.githubusercontent.com/octoblu/nanocyte-node-registry/master/registry.json'
debug = require('debug')('nanocyte-engine-simple:component-installer')
class ComponentInstaller
  constructor: (options={}, dependencies={}) ->
    {@request, @fs, @npm, ComponentLoader} = dependencies
    @request ?= require 'request'
    @fs ?= require 'fs'
    @npm ?= require 'npm'
    ComponentLoader ?= require './component-loader'

    {@registryUrl} = options
    @registryUrl ?=
      process.env.NANOCYTE_NODE_REGISTRY_URL || DEFAULT_NANOCYTE_NODE_REGISTRY_URL

    @componentLoader = new ComponentLoader options, dependencies

  downloadRegistry: (callback) =>
    fileStream = @fs.createWriteStream './nanocyte-node-registry.json'
    fileStream.on 'error', (error) => callback error
    fileStream.on 'finish', => callback()

    @request(url: @registryUrl, json: true).pipe fileStream

  installComponents: (registry, callback) =>
    @npm.load (error, result) =>
      debug "npm load:", error, result
      return callback error if error?
      components = @componentLoader.getComponentList registry
      debug "found components:", components
      @npm.commands.install components, callback

module.exports = ComponentInstaller
