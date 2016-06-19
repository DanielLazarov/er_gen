package ERDiag::WebViews::Schemas;

use strict;

use HTML::Template;
use PerlLib::Errors::Errors;

sub LoadSchema($)
{
    my ($app) = @_;

    my $sth = $$app{dbh}->prepare(q{
        SELECT *
        FROM schemas 
        WHERE schema_id = ?
    });
    $sth->execute($$app{cgi}{schema_id});
    ASSERT($sth->rows == 1);

    my $schema_row = $sth->fetchrow_hashref;

    my $template = HTML::Template->new(filename => "/usr/share/er-diag/er-web/templates/load_schema.tmpl");
    $template->param(
        USERNAME => $$schema_row{schema_json}
    );  

    return $template->output();
}

1;
