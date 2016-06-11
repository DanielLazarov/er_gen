package PerlLib::Errors::Errors;

use strict;

use Exporter qw(import);

our @ISA =   qw(Exporter);
our @EXPORT = qw(TRACE ASSERT ASSERT_PEER ASSERT_USER);


sub TRACE($;$)
{
    my ($control, $msg) = @_;

    my $time = localtime;

    print STDERR "[$time] $control: $msg \n";
}

sub ASSERT($;$$)
{
    my($cond, $msg, $code) = @_;

    if(!$cond)
    {
        my ($package, $filename, $line) = caller;
        TRACE("ASSERT FAILED:", $filename . ", Line:" . $line);
        die bless {msg => $msg, code => $code}, "sysError";
    }
}

sub ASSERT_PEER($;$$)
{
    my($cond, $msg, $code) = @_;

    if(!$cond)
    {
        my ($package, $filename, $line) = caller;
        TRACE("ASSERT_PEER FAILED", $filename .", Line:" . $line);
        die bless {msg => $msg, code => $code}, "peerError";
    }
}

sub ASSERT_USER($;$$)
{
    my($cond, $msg, $code) = @_;

    if(!$cond)
    {
        my ($package, $filename, $line) = caller;
        TRACE("ASSERT_USER FAILED", $filename . ", Line:" .$line);
        die bless {msg => $msg, code => $code}, "userError";
    }
}

1;
