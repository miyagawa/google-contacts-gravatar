google-contacts-gravatar - Imports photos from Gravatar and adds to your Google Contacts

## What you need

Perl 5.8.1 or over, libxml2 and required Perl modules from CPAN.

## How to use

Run `./google-contacts-gravatar.pl --email YOUR-EMAIL@gmail.com --password YOUR-GOOGLE-PASSWORD`

By default, if there are any photos attached to Google contacts, this script won't overwrite them. With `--overwrite` option it will overwrite photos from Gravatar. If you have more than 1000 contacts, you might want to increase the max results to something like `--max_results=2000`.

## See Also

* [Google Contacts API](http://code.google.com/apis/contacts/docs/2.0/developers_guide_protocol.html)
* [Gravatar Importer for Google](http://blog.gravatar.com/2008/10/13/gravatar-importer-google/)
* [gravatar-importer .NET](http://code.google.com/p/gravatar-importer/)

