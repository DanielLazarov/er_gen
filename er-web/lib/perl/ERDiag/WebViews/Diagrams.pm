package ERDiag::WebViews::Diagrams;

use strict;

use HTML::Template;
use PerlLib::Errors::Errors;

use ERDiag::Config::Config;

use ERDiag::Utils::SchemaJSONParser;

sub AllDiagrams($)
{
    my ($app) = @_;

    my $sth = $$app{dbh}->prepare(q{
        SELECT * 
        FROM diagrams D
            JOIN sys_users_sessions SUS ON D.sys_user_session_id = SUS.id
            JOIN sys_users SU ON SUS.sys_user_id = SU.id
        WHERE D.is_deleted IS FALSE 
          AND (? AND SU.username = ? ) OR SUS.session_id = ?      
    });
    $sth->execute($ERDiag::Config::Config::REQUIRE_LOGIN, $$app{cgi}{username}, $$app{cgi}{sess_id});
    TRACE("Found Diagrams: ", $sth->rows);

    my $rows_arrref = [];
    while( my $row = $sth->fetchrow_hashref)
    {
        push $rows_arrref, {DIAGRAM_NAME => $$row{name}, UNIQUE_IDENTIFIER => $$row{diagram_id}};
    }

    my $template = HTML::Template->new(filename => "/usr/share/er-diag/er-web/templates/all_diagrams.tmpl");


    $template->param(
        TR_LOOP => $rows_arrref
    );

    return $template->output();
}

sub SaveDiagram($)
{
    my ($app) = @_;

    my $template = HTML::Template->new(filename => "/usr/share/er-diag/er-web/templates/success.tmpl");

    $template->param(
        MSG => "Saved."
    );

    return $template->output();
}

1;
