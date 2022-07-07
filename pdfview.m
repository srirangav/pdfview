/*
    pdfview.m - display the text in a PDF

    History:

    v. 0.1.0 (07/06/2022) - Initial version

    Copyright (c) 2022 Sriranga R. Veeraraghavan <ranga@calalum.org>

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import <AppKit/AppKit.h>
#import <PDFKit/PDFKit.h>
#import <stdio.h>
#import <stdarg.h>
#import <unistd.h>
#import <string.h>

static NSString   *gUTIPDF  = @"com.adobe.pdf";
static const char *gPgmName = "pdfview";
static const char *gPgmOpts = "hq";
static BOOL       gQuiet    = NO;

enum
{
    gPgmOptHelp      = 'h',
    gPgmOptQuiet     = 'q',
};

/* prototypes */

static void printError(const char *format, ...);
static BOOL printPDF(NSURL *url);
static void printUsage(void);

/* functions */

/* printUsage - print usage statement */

static void printUsage(void)
{
    fprintf(stderr, 
            "Usage: %s [-%c] [files]\n", 
            gPgmName,
            gPgmOptQuiet);
}

/* printError - print an error message */

static void printError(const char *format, ...)
{
    va_list args;

    if (gQuiet == YES)
    {
        return;
    }

    va_start(args, format);
    fprintf(stderr,"ERROR: ");
    vfprintf(stderr, format, args);
    va_end(args);
}

/* printPDF - prints the text contained in the specified PDF */

BOOL printPDF(NSURL *url)
{
    PDFDocument *pdfDoc = nil;
    PDFPage *pdfPage = nil;
    NSUInteger pdfPages = 0, i = 0;
    NSString *pageText = nil;

    if (url == nil)
    {
        printError("No file specified!\n");
        return NO;
    }

    pdfDoc = [[PDFDocument alloc] initWithURL: url];
    if (pdfDoc == nil)
    {
        printError("Not a valid PDF!\n");
        return NO;
    }

    /* get the page count and make sure we have at least 1 page */

    pdfPages = [pdfDoc pageCount];
    if (pdfPages < 1)
    {
        printError("PDF has no pages!\n");
        return NO;
    }

    for(i = 0 ; i < pdfPages ; i++) 
    {
        pdfPage = [pdfDoc pageAtIndex: i];
        if (pdfPage == NULL)
        {
            continue;
        }
        
        pageText = [[pdfPage string] stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (pageText != nil && [pageText length] > 0)
        {
            fprintf(stdout,
                    "%s\n",
                    [pageText cStringUsingEncoding: NSUTF8StringEncoding]);
        }
    }

    return YES;
}

/* main */

int main(int argc, char * const argv[])
{
    int i = 0, err = 0, ch = 0;
    const char *file = NULL;
    BOOL optHelp = NO;
    NSFileManager *fm = nil;
    NSWorkspace *workspace = nil;
    NSString *path = nil, *type = nil;
    NSURL *fURL = nil;
    NSError *error = nil;

    /*
        create an autorelease pool:
        https://developer.apple.com/documentation/foundation/nsautoreleasepool
    */

@autoreleasepool
    {

    while ((ch = getopt(argc, argv, gPgmOpts)) != -1)
    {
        switch(ch)
        {
            case gPgmOptHelp:
                optHelp = YES;
                break;
            case gPgmOptQuiet:
                gQuiet = YES;
                break;
            default:
                printError("Unknown option: '%c'\n", ch);
                err++;
                break;
        }

        if (optHelp || err > 0)
        {
            printUsage();
            break;
        }
    }

    if (err > 0)
    {
        return err;
    }

    if (optHelp)
    {
        return 0;
    }

    argc -= optind;
    argv += optind;

    if (argc <= 0)
    {
        printError("No files specified.\n");
        printUsage();
        return 1;
    }

    fm = [NSFileManager defaultManager];
    if (fm == nil)
    {
        printError("Cannot get NSFileManager!\n");
        return NO;
    }

    workspace = [NSWorkspace sharedWorkspace];
    if (workspace == nil)
    {
        printError("Cannot get NSWorkspace!\n");
        return NO;
    }

    for (i = 0; i < argc; i++)
    {
        if (argv[i] == NULL || argv[i][0] == '\0')
        {
            err++;
            printError("Filename is NULL!\n");
            continue;
        }
        
        file = argv[i];

        /* get the full path to the file */

        path = 
            [fm stringWithFileSystemRepresentation: file
                                            length: strlen(file)];
        if (path == nil)
        {
            printError("Cannot get full path for '%s'.\n", file);
            err++;
            continue;
        }

        /* create a URL representation of the path */
        
        fURL = [NSURL fileURLWithPath: path];
        if (fURL == nil)
        {
            printError("Cannot get create URL for '%s'.\n", file);
            err++;
            continue;
        }

        /* verify that this is a PDF file */
        
        if (![fURL getResourceValue: &type
                             forKey: NSURLTypeIdentifierKey
                              error: &error])
        {
            printError("Cannot determine file type for '%s'.\n", file);
            continue;
        }

        fprintf(stderr,
                "DEBUG: TYPE = '%s'\n",
                [type cStringUsingEncoding: NSUTF8StringEncoding]);
                
        if (![workspace type: type conformsToType: gUTIPDF])
        {
            printError("Not a PDF: '%s'\n", file);
            err++;
            continue;
        }

        /* this is a valid PDF, attempt to print it */
        
        if (printPDF(fURL) != TRUE)
        {
            err++;
        }
    }

    return err;
    }
}
