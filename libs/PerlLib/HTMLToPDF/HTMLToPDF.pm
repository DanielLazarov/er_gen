package PerlLib::HTMLToPDF::HTMLToPDF;

use strict;

use Digest::MD5 qw(md5_hex);
use IO::File;
use File::Temp;

sub convert($$$)
{
    my ($html, $outfile_name, $params) = @_;

    my $filename = "/tmp/" . md5_hex(localtime . rand . localtime) . ".html";
    my $fh = IO::File->new("> $filename") or die "Cant open file $!";
    print $fh $html;
    $fh->close();
    
    `/usr/local/bin/wkhtmltopdf -q $filename $outfile_name`;
    
    unlink $filename;
}


1;
