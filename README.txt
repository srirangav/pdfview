README
------

pdfview v.0.2.1

Homepage:

   https://github.com/srirangav/pdfview

About:

    pdfview is a command line program that displays any available text
    in a PDF.  On MacOSX, pdfview uses PDFKit (which is available on
    MacOSX 10.4 or newer).  On Linux/*bsd, pdfview is a shell script
    that relies on pdftotext from either xpdf or poppler:

        https://www.xpdfreader.com/pdftotext-man.html
        https://github.com/freedesktop/poppler

    On Linux/*bsd, pdfview will wrap text using fmt(1) (first choice)
    or fold(1), if they are available.

Usage:

    pdfview [files]

Build (MacOSX only):

    $ ./configure
    $ make

Install:

    On MacOSX:

        $ ./configure
        $ make
        $ make install

        By default, pdfview is installed in /usr/local/bin.  To install
        it in a different location, the alternate installation prefix
        can be supplied to configure:

            $ ./configure --prefix="<prefix>"

        or, alternately to make:

            $ make install PREFIX="<prefix>"

        For example, the following will install pdfview in /opt/local:

            $ make PREFIX=/opt/local install

        A DESTDIR can also be specified for staging purposes (with or
        without an alternate prefix):

            $ make DESTDIR="<destdir>" [PREFIX="<prefix>"] install

    On Linux/*bsd:

        Put pdfview.sh somewhere in your $PATH, for example:

            $ cp pdfview.sh $HOME/bin/pdfview
            $ chmod u+x $HOME/bin/pdfview

History:

    v.0.2.1  Add page numbering support to MacOSX version
    v.0.2.0  Add PDFKit based implementation for MacOSX
    v.0.1.3  Fixes based on shellcheck
    v.0.1.2  Minor change for Debian
    v.0.1.1  Update README.txt to mention MacOSX, FreeBSD,
             and OpenBSD
    v.0.1.0  Initial release

Platforms:

    pdfview has been tested on MacOSX (11.x).  pdfview.sh has
    been tested on FreeBSD (13.0), OpenBSD (7.0), and Debian (11.x).
    It should work on other systems that have pdftotext installed.

References:

   https://stackoverflow.com/questions/3570591
   https://unix.stackexchange.com/questions/25173

License:

    See LICENSE.txt
