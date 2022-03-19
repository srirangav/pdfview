README
------

pdfview.sh v0.1
By Sriranga Veeraraghavan <ranga@calalum.org>

Homepage:

   https://github.com/srirangav/pdfview.sh

Install:

    Put pdfview.sh in a directory in your $PATH, e.g.:

    $ cp pdfview.sh $HOME/bin
    $ chmod u+x $HOME/bin/pdfview.sh

Running pdfview.sh:

    $ pdfview.sh [-c columns] [PDF]

    If the -c option is specified, pdfview will try to wrap
    the output to the specified number of columns.

History:

    v.0.1.0  Initial release

License:

    See LICENSE.txt

Notes:

   pdfview.sh relies on pdftotext from xpdf or poppler:

   https://www.xpdfreader.com/pdftotext-man.html
   https://github.com/freedesktop/poppler

   pdfview.sh will wrap text using fmt(1) (first choice)
   or fold(1), if they are available

References:

   https://stackoverflow.com/questions/3570591
   https://unix.stackexchange.com/questions/25173 

