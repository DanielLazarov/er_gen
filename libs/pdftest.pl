use warnings;
use strict;

use PerlLib::HTMLToPDF::HTMLToPDF;


my $html = "<html><head></head><body><h1>Some shitsddsgsdgdsgdsg</h1></body></html>";

PerlLib::HTMLToPDF::HTMLToPDF::convert($html, "test.pdf", {});
