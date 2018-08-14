PREFIX ?= /usr/lib/password-store

.PHONY: install

install:
	install -d $(PREFIX)/extensions
	install -m 755 diceware.bash $(PREFIX)/extensions
	install -m 744 diceware.wordlist.asc $(PREFIX)/extensions
