/*
    pdfview.m - display the text in a PDF

    History:

    v. 0.1.0  (07/06/2022) - Initial version
    v. 0.1.1  (07/11/2022) - add page numbering support
    v. 0.1.2  (07/13/2022) - move page numbering support to a separate
                             function
    v. 0.1.3  (07/21/2022) - add expression matching support
    v. 0.1.4  (07/24/2022) - add support for printing counts of matches
    v. 0.1.5  (07/25/2022) - allow searching to stop once the first
                             match is found
    v. 0.1.6  (07/25/2022) - add support for printing counts only on
                             matching pages and for printing filenames
                             only when no matches are found in a file
    v. 0.1.7  (07/26/2022) - add support for dehyphenation and removing
                             smart quotes, long hypens, etc.
    v. 0.1.8  (07/27/2022) - add additional formatting
    v. 0.1.9  (10/29/2022) - add support for Monterey (MacOSX 12.0)
    v. 0.1.10 (05/06/2023) - add support for printing particular pages
    v. 0.1.11 (05/06/2023) - add support for printing PDF metadata

    Copyright (c) 2022-2023 Sriranga R. Veeraraghavan <ranga@calalum.org>

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

/*
    use Uniform Type Identifiers, if available
    see: https://stackoverflow.com/questions/70512722
*/

#ifdef HAVE_UTT
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#endif /* HAVE_UTT */

#import <stdio.h>
#import <stdarg.h>
#import <unistd.h>
#import <string.h>
#import <ctype.h>

/* globals */

static BOOL gQuiet = NO;

/* constants */

#ifndef HAVE_UTT
static NSString   *gUTIPDF      = @"com.adobe.pdf";
#endif /* HAVE_UTT */

/* program name and version */

static const char *gPgmName     = "pdfview";
static const char *gPgmVersion  = "0.4.0";

/* text replacements for formatted definitions */

static const NSDictionary *gReplacements =
@{
    @"“": @"\"",
    @"”": @"\"",
    @"’": @"'",
    @"‘": @"'",
    @"–": @"-"
};

/*
    command line options:

        -h - help
        -d - dehyphenate
        -n - print filename and page number
        -q - quiet mode (no errors / info messages)
        -r - raw mode, do not make any changes to the text, other
             than dehyphenating (if requested)
        -e - print lines that match the specified expression
        -c - if an expression is specified, print the total matches
             instead of each matching line
        -i - if an expression is specified, when looking for matches,
             ignore case
        -l - if an expression is specified, stop searching once a
             match is found and just print out the file name
        -L - if an expression is specified, print out the file name
             only if no matches are found in a file
        -m - only list metadata / information about each file
        -p - only display the specified pages
        -t - if an expression is specified, print the total matches
             per page
        -T - if an expression is specified, print the total matches
             per page only on pages where there are matches
        -v - print the version
*/

enum
{
    gPgmOptCount       = 'c',
    gPgmOptDehyphenate = 'd',
    gPgmOptHelp        = 'h',
    gPgmOptRegex       = 'e',
    gPgmOptIgnoreCase  = 'i',
    gPgmOptListOnly    = 'l',
    gPgmOptMetadata    = 'm',
    gPgmOptPageNum     = 'n',
    gPgmOptPages       = 'p',
    gPgmOptQuiet       = 'q',
    gPgmOptRaw         = 'r',
    gPgmOptPageCount   = 't',
    gPgmOptVersion     = 'v',
    gPgmOptListOnlyWhenNoMatches = 'L',
    gPgmOptPageCountMatchingOnly = 'T',
};

static const char *gPgmOpts = "cdhilLmntTqrve:p:";

/* options */

typedef struct
{
    BOOL printPageNum;
    BOOL ignoreCase;
    BOOL countOnly;
    BOOL printPageCounts;
    BOOL pageCountsForMatchingPagesOnly;
    BOOL listOnly;
    BOOL listOnlyWhenNoMatches;
    BOOL dehyphenate;
    BOOL useRawText;
    const char *regex;
    NSUInteger totalMatches;
    NSMutableIndexSet *pagesToPrint;
} pdfview_opts_t;

/* prototypes */

static void printUsage(void);
static void printError(const char *format, ...);
static void printVersion(void);
static BOOL isValidRange(const char *range);
static BOOL makePageSetFromRange(const char *range,
                                 NSIndexSet *pageSet);
static BOOL printPDF(NSURL *url, pdfview_opts_t *opts);
static BOOL printPDFPage(NSString *pageText,
                         NSUInteger pageNo,
                         NSString *fileName,
                         pdfview_opts_t *opts);
static BOOL printPDFMetadata(NSURL *url);

/* functions */

/* printUsage - print usage statement */

static void printUsage(void)
{
    fprintf(stderr,
            "Usage: %s [-%c] [-%c] [-%c] [-%c] [-%c [expression] -%c [-%c|-%c] [-%c|-%c] -%c] [-%c [pages]] [files]\n",
            gPgmName,
            gPgmOptQuiet,
            gPgmOptPageNum,
            gPgmOptDehyphenate,
            gPgmOptRaw,
            gPgmOptRegex,
            gPgmOptCount,
            gPgmOptPageCount,
            gPgmOptPageCountMatchingOnly,
            gPgmOptListOnly,
            gPgmOptListOnlyWhenNoMatches,
            gPgmOptIgnoreCase,
            gPgmOptPages);
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

/* printVersion - print the program version */

static void printVersion(void)
{
    fprintf(stdout, "%s: version %s\n", gPgmName, gPgmVersion);
}

/*
   isValidRange - checks to see if the specified range contains
                  only numbers, commas (','), or dashes ('-')
*/

static BOOL isValidRange(const char *range)
{
    const char *p = NULL;
    BOOL validRange = NO;

    if (range == NULL || range[0] == '\0')
    {
        return validRange;
    }

    p = range;

    /* confirm that the range starts with a number */

    if (isnumber((int)*p) == 0)
    {
        return validRange;
    }

    validRange = YES;
    p++;
    while (validRange == YES && *p != '\0')
    {
        if (isnumber((int)*p) != 0 ||
            *p == ',' || *p == '-')
        {
            p++;
            continue;
        }
        validRange = NO;
    }

    return validRange;
}

static BOOL makePageSetFromRange(const char *range,
                                 NSMutableIndexSet *pageSet)
{
    NSString *rawRange = nil;
    NSArray *requestedPages = nil;
    NSRange subRange;
    NSEnumerator *enumerator = nil;
    id requestedPage;

    if (range == NULL || pageSet == nil)
    {
        return NO;
    }

    if (isValidRange(range) != YES)
    {
        return NO;
    }

    rawRange = [NSString stringWithUTF8String: range];
    if (rawRange == nil)
    {
        return NO;
    }

    requestedPages = [rawRange componentsSeparatedByString: @","];
    if (requestedPages == nil)
    {
        return NO;
    }

    enumerator = [requestedPages objectEnumerator];
    if (enumerator == nil)
    {
        return NO;
    }

    while ((requestedPage = [enumerator nextObject]) != nil)
    {
        subRange = NSRangeFromString(requestedPage);
        if (subRange.location == 0 && subRange.length == 0)
        {
            continue;
        }

        if (subRange.location > 0 && subRange.length == 0)
        {
            [pageSet addIndex: subRange.location];
            continue;
        }

        [pageSet addIndexesInRange:
            NSMakeRange(subRange.location,
                        (subRange.length - subRange.location)+1)];
    }

    if ([pageSet count] <= 0)
    {
        return NO;
    }

    return YES;
}

/* printPDFPage - prints the text for a particular page of a PDF */

static BOOL printPDFPage(NSString *pageText,
                         NSUInteger pageNum,
                         NSString *fileName,
                         pdfview_opts_t *opts)
{
    NSString *line = nil;
    NSMutableArray *lines = nil;
    NSUInteger numLines = 0, i = 0, matchesInPage = 0;
    BOOL printPageNum = NO;
    BOOL printCountOnly = NO;
    BOOL printPageCount = NO, matchingPagesOnly = NO;
    BOOL stopIfMatchFound = NO;

    if (pageText == nil || pageNum < 1)
    {
        return NO;
    }

    lines = [[pageText componentsSeparatedByCharactersInSet:
             [NSCharacterSet newlineCharacterSet]] mutableCopy];
    if (lines == nil)
    {
        return NO;
    }

    numLines = [lines count];
    if (numLines < 1)
    {
        return NO;
    }

    if (opts != NULL)
    {
        printPageNum = opts->printPageNum;
        printCountOnly = opts->countOnly;
        printPageCount = opts->printPageCounts;
        stopIfMatchFound = opts->listOnly;

        if (opts->pageCountsForMatchingPagesOnly == YES)
        {
            printPageCount = YES;
            matchingPagesOnly = YES;
        }
    }

    /*
        On MacOSX 10.7 and newer, enable support for printing
        lines that match a user specified regular expression.
    */

    if (@available(macos 10.7, *))
    {
        NSError *error = nil;
        NSString *regexStr = nil;
        NSRegularExpression *regex = nil;
        NSUInteger ignoreCase = 0, numMatches = 0;

        if (opts != NULL && opts->regex != NULL)
        {
            regexStr = [NSString stringWithUTF8String: opts->regex];
            if (regexStr != nil)
            {
                if (opts->ignoreCase == YES)
                {
                    ignoreCase = NSRegularExpressionCaseInsensitive;
                }
                regex = [NSRegularExpression
                            regularExpressionWithPattern: regexStr
                                                 options: ignoreCase
                                                   error: &error];
            }
        }

        for (i = 0; i < numLines; i++)
        {
            line = [lines objectAtIndex: i];
            if (line == nil)
            {
                continue;
            }

            /*
                a regex is available, so check to see if this line
                contains a match
            */

            if (regex != nil)
            {
                /* get the number of matches in this line */

                numMatches =
                    [regex numberOfMatchesInString: line
                                           options: 0
                                             range: NSMakeRange(0, [line length])];

                if (stopIfMatchFound == YES)
                {
                    if (numMatches > 0)
                    {
                        opts->totalMatches += numMatches;
                        break;
                    }
                }

                if (printPageCount == YES)
                {
                    matchesInPage += numMatches;
                    if (printCountOnly == NO)
                    {
                        continue;
                    }
                }

                if (printCountOnly == YES)
                {
                    opts->totalMatches += numMatches;
                    continue;
                }

                /* no matches, skip this line */

                if (numMatches <= 0)
                {
                    continue;
                }
            }

            /* print the filename and page number, if requested */

            if (printPageNum == YES)
            {
                if (fileName != nil)
                {
                    fprintf(stdout,
                            "%s:",
                            [fileName cStringUsingEncoding: NSUTF8StringEncoding]);
                }

                fprintf(stdout, "%ld:", pageNum);
            }

            /* print the line */

            fprintf(stdout,
                    "%s\n",
                    [line cStringUsingEncoding: NSUTF8StringEncoding]);
        }

        if (printPageCount == YES &&
            regex != nil &&
            stopIfMatchFound != YES)
        {

            if (matchingPagesOnly && matchesInPage <= 0)
            {
                return YES;
            }

            if (fileName != nil)
            {
                fprintf(stdout,
                        "%s:",
                        [fileName cStringUsingEncoding: NSUTF8StringEncoding]);
            }

            fprintf(stdout, "%ld:%ld\n", pageNum, matchesInPage);
        }
    }
    else
    {
        for (i = 0; i < numLines; i++)
        {
            line = [lines objectAtIndex: i];
            if (line == nil)
            {
                continue;
            }

            if (printPageNum)
            {
                if (fileName != nil)
                {
                    fprintf(stdout,
                            "%s:",
                            [fileName cStringUsingEncoding: NSUTF8StringEncoding]);
                }

                fprintf(stdout, "%ld:", pageNum);
            }

            fprintf(stdout,
                    "%s\n",
                    [line cStringUsingEncoding: NSUTF8StringEncoding]);
        }
    }

    return YES;
}

/* printPDF - prints the text contained in the specified PDF */

static BOOL printPDF(NSURL *url, pdfview_opts_t *opts)
{
    PDFDocument *pdfDoc = nil;
    PDFPage *pdfPage = nil;
    NSUInteger pdfPages = 0, i = 0, j = 0;
    NSUInteger firstPage = 0, lastPage = 0;
    NSMutableString *pageText = nil;
    NSString *rawText = nil;
    NSString *fileName = nil;
    id origStr;
    NSEnumerator *replEnumerator = nil;
    BOOL printLines = NO;
    BOOL printCountOnly = NO;
    BOOL stopIfMatchFound = NO;
    BOOL dehyphenate = NO;
    BOOL useRawText = NO;
    BOOL havePages = NO;

    if (url == nil)
    {
        printError("No file specified!\n");
        return NO;
    }

    if (opts != NULL)
    {
        if (opts->printPageNum == YES)
        {
            printLines = YES;
            fileName = [url lastPathComponent];
        }

        dehyphenate = opts->dehyphenate;
        useRawText = opts->useRawText;

        if (opts->regex != NULL)
        {
            printLines = YES;

            if (fileName == nil)
            {
                fileName = [url lastPathComponent];
            }

            printCountOnly = opts->countOnly;

            if (opts->listOnly == YES)
            {
                stopIfMatchFound = YES;
            }
        }

        if (opts->pagesToPrint != nil)
        {
            havePages = YES;
            firstPage = [opts->pagesToPrint firstIndex];
            if (firstPage == NSNotFound)
            {
                firstPage = 0;
                havePages = NO;
            }

            lastPage = [opts->pagesToPrint lastIndex];
            if (lastPage == NSNotFound)
            {
                firstPage = 0;
                lastPage = 0;
                havePages = NO;
            }
        }
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

        /* if particular pages are requested, skip all other pages */

        if (havePages)
        {
            j = i+1;

            /* past the last requested page, we are done */

            if (j > lastPage)
            {
                break;
            }

            /* before the first requested page, move on */

            if (j < firstPage)
            {
                continue;
            }

            /* is this page requested? if not, move on */

            if ([opts->pagesToPrint containsIndex: j] == NO)
            {
                continue;
            }
        }

        /* get the current page */

        pdfPage = [pdfDoc pageAtIndex: i];
        if (pdfPage == NULL)
        {
            continue;
        }

        /* get the text on this page */

        rawText = [pdfPage string];
        if (rawText == nil)
        {
            continue;
        }

        pageText = [[rawText stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceAndNewlineCharacterSet]]
                    mutableCopy];
        if (pageText == nil || [pageText length] <= 0)
        {
            continue;
        }

        if (dehyphenate == YES)
        {
            [pageText replaceOccurrencesOfString: @"- "
                                      withString: @""
                                         options: NSLiteralSearch
                                           range: NSMakeRange(0,
                                                 [pageText length])];
            if ([pageText length] <= 0)
            {
                continue;
            }

            [pageText replaceOccurrencesOfString: @"-\n"
                                      withString: @""
                                         options: NSLiteralSearch
                                           range: NSMakeRange(0,
                                                 [pageText length])];
            if ([pageText length] <= 0)
            {
                continue;
            }

        }
        else
        {
            [pageText replaceOccurrencesOfString: @"- "
                                      withString: @"-\n"
                                         options: NSLiteralSearch
                                           range: NSMakeRange(0,
                                                 [pageText length])];
            if ([pageText length] <= 0)
            {
                continue;
            }
        }

        /* unless rawtext is requested, perform some text replacements */

        if (useRawText != YES)
        {

            replEnumerator = [gReplacements keyEnumerator];
            if (replEnumerator != nil)
            {
                origStr = [replEnumerator nextObject];
                while (origStr != nil && [pageText length] > 0)
                {
                    [pageText replaceOccurrencesOfString: origStr
                                              withString:
                                                [gReplacements objectForKey: origStr]
                                                 options: NSLiteralSearch
                                                   range: NSMakeRange(0,
                                                          [pageText length])];
                    origStr = [replEnumerator nextObject];
                }
            }

        }

        if ([pageText length] > 0)
        {

            /*
                if page numbering is requested, if possible, split
                string representation of the page on newlines and
                print the file name and page number as a prefix
                to each line.
            */

            if (printLines)
            {
                if (printPDFPage(pageText, i+1, fileName, opts) == YES)
                {
                    if (stopIfMatchFound == YES)
                    {
                        if (opts->totalMatches <= 0)
                        {
                            continue;
                        }
                        break;
                    }
                    else
                    {
                        continue;
                    }
                }

                if (fileName != nil)
                {
                    fprintf(stdout,
                            "%s:",
                            [fileName cStringUsingEncoding: NSUTF8StringEncoding]);
                }

                fprintf(stdout, "%ld:", i+1);
            }

            fprintf(stdout,
                    "%s\n",
                    [pageText cStringUsingEncoding: NSUTF8StringEncoding]);
        }
    }

    if (stopIfMatchFound == YES &&
        opts != NULL &&
        opts->totalMatches > 0)
    {
        if (fileName != nil &&
            opts != NULL &&
            opts->listOnlyWhenNoMatches == NO)
        {
            fprintf(stdout,
                    "%s\n",
                    [fileName cStringUsingEncoding: NSUTF8StringEncoding]);
        }
        return YES;
    }

    if (opts != NULL &&
        opts->listOnlyWhenNoMatches == YES &&
        opts->totalMatches <= 0 &&
        fileName != nil)
    {
        fprintf(stdout,
                "%s\n",
                [fileName cStringUsingEncoding: NSUTF8StringEncoding]);
    }

    if (printCountOnly == YES)
    {
        if (fileName != nil)
        {
            fprintf(stdout,
                    "%s:",
                    [fileName cStringUsingEncoding: NSUTF8StringEncoding]);
        }
        fprintf(stdout, "%ld\n", opts->totalMatches);
    }

    return YES;
}

/* printPDFMetadata - print the metadata for the specified PDF */

static BOOL printPDFMetadata(NSURL *url)
{
    PDFDocument *pdfDoc = nil;
    NSString *fileName = nil;
    NSMutableString *pdfRestrictions = nil;
    NSUInteger pdfPages = 0;

    if (url == nil)
    {
        printError("No file specified!\n");
        return NO;
    }

    fileName = [url lastPathComponent];
    if (fileName == nil)
    {
        fileName = @"";
    }

    pdfDoc = [[PDFDocument alloc] initWithURL: url];
    if (pdfDoc == nil)
    {
        printError("%s: Not a valid PDF!\n",
                   [fileName cStringUsingEncoding: NSUTF8StringEncoding]);
        return NO;
    }

    fprintf(stdout, "%s: ",
            [fileName cStringUsingEncoding: NSUTF8StringEncoding]);

    pdfPages = [pdfDoc pageCount];
    fprintf(stdout, "%ld page%s",
            pdfPages, (pdfPages == 1 ? "" : "s"));

    if ([pdfDoc isEncrypted] == YES)
    {
        fprintf(stdout, ", encrypted");
    }

    if ([pdfDoc isLocked] == YES)
    {
        fprintf(stdout, ", locked");
    }

    pdfRestrictions = [[NSMutableString alloc] init];
    if (pdfRestrictions == nil)
    {
        fprintf(stdout, "\n");
        return NO;
    }

    if ([pdfDoc allowsCopying] == NO)
    {
        [pdfRestrictions appendFormat: @", %s", "copying"];
    }

    if ([pdfDoc allowsPrinting] == NO)
    {
        [pdfRestrictions appendFormat: @", %s", "printing"];
    }

    if (@available(macos 10.13, *))
    {
        if ([pdfDoc allowsDocumentChanges] == NO ||
            [pdfDoc allowsDocumentAssembly] == NO)
        {
            [pdfRestrictions appendFormat: @", %s", "changes"];
        }

        if ([pdfDoc allowsCommenting] == NO)
        {
            [pdfRestrictions appendFormat: @", %s", "comments"];
        }
    }

    if ([pdfRestrictions length] > 0)
    {
        fprintf(stdout, ", No %s",
                [pdfRestrictions cStringUsingEncoding: NSUTF8StringEncoding]);
    }

    fprintf(stdout, "\n");

    return YES;
}

/* main */

int main(int argc, char * const argv[])
{
    int i = 0, err = 0, ch = 0;
    const char *file = NULL;
    BOOL optHelp = NO;
    BOOL optVersion = NO;
    BOOL optMetaDataOnly = NO;
    NSFileManager *fm = nil;
    NSWorkspace *workspace = nil;
    NSString *path = nil;
    NSURL *fURL = nil;
    NSString *type = nil;
    NSError *error = nil;
    pdfview_opts_t opts;
#ifdef HAVE_UTT
    UTType *utt = nil;
#endif

    /*
        create an autorelease pool:
        https://developer.apple.com/documentation/foundation/nsautoreleasepool
    */

@autoreleasepool
    {

    opts.printPageNum = NO;
    opts.ignoreCase = NO;
    opts.countOnly = NO;
    opts.printPageCounts = NO;
    opts.pageCountsForMatchingPagesOnly = NO;
    opts.listOnly = NO;
    opts.listOnlyWhenNoMatches = NO;
    opts.dehyphenate = NO;
    opts.useRawText = NO;
    opts.regex = NULL;
    opts.totalMatches = 0;
    opts.pagesToPrint = nil;

    while ((ch = getopt(argc, argv, gPgmOpts)) != -1)
    {
        switch(ch)
        {
            case gPgmOptVersion:
                optVersion = YES;
                break;
            case gPgmOptHelp:
                optHelp = YES;
                break;
            case gPgmOptQuiet:
                gQuiet = YES;
                break;
            case gPgmOptPageNum:
                opts.printPageNum = YES;
                break;
            case gPgmOptDehyphenate:
                opts.dehyphenate = YES;
                break;
            case gPgmOptRaw:
                opts.useRawText = YES;
                break;
            case gPgmOptListOnly:
                opts.listOnly = YES;
                break;
            case gPgmOptListOnlyWhenNoMatches:
                opts.listOnly = YES;
                opts.listOnlyWhenNoMatches = YES;
                break;
            case gPgmOptIgnoreCase:
                opts.ignoreCase = YES;
                break;
            case gPgmOptCount:
                opts.countOnly = YES;
                break;
            case gPgmOptPageCount:
                opts.printPageCounts = YES;
                break;
            case gPgmOptPageCountMatchingOnly:
                opts.printPageCounts = YES;
                opts.pageCountsForMatchingPagesOnly = YES;
                break;
            case gPgmOptMetadata:
                optMetaDataOnly = YES;
                break;
            case gPgmOptPages:
                if (optarg[0] == '\0')
                {
                    printError("No pages specified\n");
                    err++;
                    break;
                }

                opts.pagesToPrint = [[NSMutableIndexSet alloc] init];
                if (makePageSetFromRange(optarg, opts.pagesToPrint) == NO)
                {
                    printError("Can't create page set from specification: %s\n",
                               optarg);
                    err++;
                    break;
                }

                break;

            case gPgmOptRegex:
                if (optarg[0] == '\0')
                {
                    fprintf(stderr,"Error: No expression specified\n");
                    err++;
                }
                else
                {
                    opts.regex = optarg;
                }
                break;
            default:
                if (ch != '?')
                {
                    printError("Unknown option: '%c'\n", ch);
                }
                err++;
                break;
        }

        if (optHelp == YES || err > 0)
        {
            printUsage();
            break;
        }

        if (optVersion == YES)
        {
            printVersion();
            break;
        }

        if (optMetaDataOnly == YES)
        {
            break;
        }
    }

    if (err > 0)
    {
        return err;
    }

    if (optHelp == YES || optVersion == YES)
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

#ifdef HAVE_UTT
        utt = [UTType typeWithIdentifier: type];
        if (![utt conformsToType: UTTypePDF])
#else
        if (![workspace type: type conformsToType: gUTIPDF])
#endif
        {
            printError("Not a PDF: '%s'\n", file);
            err++;
            continue;
        }

        if (optMetaDataOnly)
        {
            if (printPDFMetadata(fURL) != TRUE)
            {
                err++;
            }
            continue;
        }

        /* this is a valid PDF, attempt to print it */

        if (printPDF(fURL, &opts) != TRUE)
        {
            err++;
        }

        /* reset the total number of matches */

        opts.totalMatches = 0;

        /* if particular pages to display were specified, ignore
           any additional files that may be been provided on the
           command line */

        if (opts.pagesToPrint != nil)
        {
            break;
        }
    }

    return err;
    }
}
