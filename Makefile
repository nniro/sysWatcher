#! /bin/sh

installDir=/usr/share/sysWatcher
filesToInstall=utils.sh runScriptFunc.sh

install: $(filesToInstall)
	install -d $(installDir)
	install $(filesToInstall) $(installDir)

uninstall: $(filesToInstall)
	rm -Rf $(installDir)
