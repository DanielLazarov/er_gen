use warnings;
use strict;

use DBI;
use Try::Tiny;

use PerlLib::Security::Security;


sub printHelp()
{
    print "
    Usage:
        perl create_sys_user <username> <password>
    ";
}

if( ! defined $ARGV[0] || ! defined $ARGV[1])
{
    printHelp();
}
else
{
    my $dbh = DBI->connect("DBI:Pg:dbname=er_diag;host=localhost", "er_diagweb", "c7bd08ef40d608eb4fd84ba51c2a5ff5", {RaiseError => 1, AutoCommit => 0});
    $dbh->{pg_enable_utf8} = 1;
    try
    {
        #TODO Consts in settings;

        my $username = $ARGV[0];
        my $password = $ARGV[1];

        PerlLib::Security::Security::createUser({dbh => $dbh}, $username, $password);
        $dbh->commit();        
        print "Done.\n";
        $dbh->disconnect();
    }
    catch
    {
        my $err = shift;
        if($dbh)
        {
            $dbh->rollback();
            $dbh->disconnect();
        }
        print "ERR: " . $$err{msg} . " " . $$err{code} . "\n";
    };
    
}
