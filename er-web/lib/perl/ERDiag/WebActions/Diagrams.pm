package ERDiag::WebActions::Diagrams;

use strict;

use PerlLib::Errors::Errors;

use ERDiag::Utils::SchemaJSONParser;

sub DeleteDiagram($)
{
    my ($app) = @_;

    my $sth = $$app{dbh}->prepare(q{
        UPDATE diagrams
        SET is_deleted = TRUE
        WHERE diagram_id = ?    
    });
    $sth->execute($$app{cgi}{diagram_id});

    return;
}

sub CreateOrUpdateDiagram($)
{
    my ($app) = @_;

    my $parsed_schema;
    if( defined $$app{cgi}{schema_json})
    {
        $parsed_schema = ERDiag::Utils::SchemaJSONParser::FromWebToSchema($$app{cgi}{schema_json});
    }
    elsif( defined $$app{cgi}{ddl} && defined $$app{cgi}{dialect})
    {
        $parsed_schema = ERDiag::Utils::SchemaJSONParser::FromDDLToSchema($$app{cgi}{ddl}, $$app{cgi}{dialect});
    }
    else
    {
        ASSERT(0);
    }

    my $sth;
    if(defined $$app{cgi}{diagram_id})#Update
    {
        $sth = $$app{dbh}->prepare(q{
            UPDATE diagrams
            SET schema_json = ?,
                name = ?
            WHERE diagram_id = ?
            RETURNING * 
        });
        $sth->execute($parsed_schema, $$app{cgi}{diagram_name}, $$app{cgi}{diagram_id});
        ASSERT($sth->rows == 1);
    }
    else
    {
        $sth = $$app{dbh}->prepare(q{
            INSERT INTO diagrams(name, schema_json, sys_user_session_id)
            VALUES(?, ?, ?) 
            RETURNING *   
        });
        $sth->execute($$app{cgi}{diagram_name}, $parsed_schema, $$app{session_row}{id});
        ASSERT($sth->rows == 1);
    }
    
    my $row = $sth->fetchrow_hashref;
    $$app{diagram_row} = $row;

    return;
}

1;
