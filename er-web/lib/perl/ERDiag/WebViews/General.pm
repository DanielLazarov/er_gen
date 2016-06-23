package ERDiag::WebViews::General;

use strict;

use HTML::Template;
use PerlLib::Errors::Errors;

use ERDiag::Utils::SchemaJSONParser;

sub loginPage($)
{
    my ($app) = @_;

    my $template = HTML::Template->new(filename => "/usr/share/er-diag/er-web/templates/login_page.tmpl");

    if($$app{success_register})
    {
        $template->param(
            SUCCESS => 1,
            MSG => "Successful registration, please",
            CODE => "Login",
            USERNAME => $$app{cgi}{username} // ""
        );
    }
    return $template->output();
}

sub homePage($)
{
    my ($app) = @_;

    my $template = HTML::Template->new(filename => "/usr/share/er-diag/er-web/templates/home_page.tmpl");

    my $username = $$app{cgi}{username};
    ASSERT(defined $username && $username ne "");

    my $is_full_page = 0;
    if($$app{cgi}{view} eq "home_page")
    {
        $is_full_page = 1;
    }

    my $diagram_name;
    my $diagram_id;
    my $schema_json;
    if(defined $$app{diagram_row})
    {
        $diagram_name = $$app{diagram_row}{name};
        $diagram_id = $$app{diagram_row}{diagram_id};
        $schema_json = $$app{diagram_row}{schema_json};
    }
    elsif(defined $$app{cgi}{diagram_id} && ! defined $$app{cgi}{action})
    {
        my $sth = $$app{dbh}->prepare(q{
            SELECT *
            FROM diagrams
            WHERE diagram_id = ?
            AND is_deleted IS FALSE    
        });
        $sth->execute($$app{cgi}{diagram_id});
        ASSERT($sth->rows <= 1);
        ASSERT_USER($sth->rows == 1, "Unexisting or deleted diagram");
        
        my $row = $sth->fetchrow_hashref;
        $diagram_name = $$row{name};
        $diagram_id = $$row{diagram_id};
        $schema_json = $$row{schema_json};
        
        $sth = $$app{dbh}->prepare(q{
            UPDATE last_diagram_by_session
            SET diagram_id = ?
            WHERE sys_user_session_id = ? 
        });
        $sth->execute($$row{id}, $$app{session_row}{id});

        if($sth->rows == 0)
        {
            $sth = $$app{dbh}->prepare(q{
                INSERT INTO last_diagram_by_session(sys_user_session_id, diagram_id)
                VALUES(?, ?)
            }); 
            $sth->execute($$app{session_row}{id}, $$row{id});
            ASSERT($sth->rows == 1);
        }
    }
    else
    {
        my $sth = $$app{dbh}->prepare(q{
            SELECT 
                D.diagram_id,
                D.name,
                D.schema_json
            FROM last_diagram_by_session LDBS
                JOIN diagrams D ON LDBS.diagram_id = D.id
            WHERE LDBS.sys_user_session_id = ?
            AND D.is_deleted IS FALSE    
        });
        $sth->execute($$app{session_row}{id});
        ASSERT($sth->rows <= 1);

        if($sth->rows == 1)
        {
            my $row = $sth->fetchrow_hashref;
            $diagram_name = $$row{name};
            $diagram_id = $$row{diagram_id}; 
            $schema_json = $$row{schema_json};
        }
    }

    $schema_json = ERDiag::Utils::SchemaJSONParser::ToWeb($schema_json);
    
    $template->param(
        USERNAME => $username,
        HOME_FULL_TOP => $is_full_page,
        HOME_FULL_BOTTOM => $is_full_page,
        LOGOUT => $ERDiag::Config::Config::REQUIRE_LOGIN,
        DIAGRAM_NAME => $diagram_name,
        DIAGRAM_ID => $diagram_id,
        SCHEMA_JSON => $schema_json
    );
    
    return $template->output();
}

sub registerPage($)
{
    my ($app) = @_;

    my $template = HTML::Template->new(filename => "/usr/share/er-diag/er-web/templates/register_page.tmpl");

    return $template->output();
}

1;
