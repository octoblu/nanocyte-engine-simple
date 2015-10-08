ComponentInstaller = require '../src/models/component-installer'
installer = new ComponentInstaller()
installer.downloadRegistry =>
  
  registry = require '../nanocyte-node-registry.json'
  installer.installComponents registry, (error, result) =>
    if error?
      console.error "preinstall failed! Nanocyte components probably aren't installed"
      process.exit 1

    console.log "nanocyte components installed"
