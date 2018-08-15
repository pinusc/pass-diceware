# pass-diceware
A pass extension to generate passwords using [the diceware method](http://world.std.com/%7Ereinhold/diceware.html)

## Usage
Generate and insert a passhprase of 6 words:

    $ pass diceware Email/example.com 6

To install system-wide, run

    $ sudo make install
    
To install for user only, run

    $ cp diceware.bash $HOME/.password-store/.extensions
    $ cp diceware.wordlist.asc $HOME/.password-store/.extensions
    
By default, ``pass`` does not run extensions installed by the user; you'll need to add the following line to your ``.bashrc`` in order to tell it to enable them:

    PASSWORD_STORE_ENABLE_EXTENSIONS=true

### Use your own diceware file
Just run:

    $ pass diceware --diceware-file diceware.wordlist.asc Email/example.com 6

The default behaviour is to try to use one of the following two files, in this order: ``$HOME/.password-store/.extensions/diceware.wordlist.asc`` and ``/usr/lib/password-store/extensions/diceware.wordlist.asc``. 

So, if you want to override the default file, regardless of whether you have a system-wide install or a user install, just save your own diceware file as ``$HOME/.password-store/.extensions/diceware.wordlist.asc`` (you must rename it to ``diceware.wordlist.asc``)

### Security
The only absoutely secure method to generate a diceware passphrase is to throw a casino die on a hard surface in an empty roon with the curtains closed and never write it down. 

This program generates passwords (essentially) by running ``cat diceware.wordlist.asc | shuf LENGTH``. The ``shuf`` program uses entropy from ``/dev/urandom``, which should be secure enough for most purposes. It's what ``pass generate`` uses anyway. 

If the provided diceware wordlist begins with ``-----BEGIN PGP SIGNED MESSAGE-----``, i.e. is clearsigned with gpg, it will be verified with ``gpg --verify`` and the result will be printed on screen. 

If no signature is found, the program will print a warning. It is recommended to use a signed file to ensure the word list has not been tampered with. The file provided in this repo (and used by default) has been signed by me, as I found the original signature to be invalid.
