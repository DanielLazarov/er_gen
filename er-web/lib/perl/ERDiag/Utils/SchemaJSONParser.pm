package ERDiag::Utils::SchemaJSONParser;

use strict;

use SQL::Translator; 
use JSON;
use Data::Dumper;

use PerlLib::Errors::Errors;

sub FromWebToSchema($)
{
    my ($json) = @_;

    my $result = {};

    my $parsed_input = from_json($json);

    for my $table (@{$$parsed_input{nodeDataArray}})
    {
        $$result{$$table{key}} = {
            name => $$table{key},
            loc => $$table{loc},
            fields => [] 
        };

        for my $field (@{$$table{fields}})
        {
            my $parsed_field = {
                name => $$field{name},
                data_type => $$field{type},
                default_value => $$field{default},
                fkey_ref => undef,
                is_unique => 0,
                is_nullable => 1,
                is_foreign_key => 0,
                is_primary_key => 0,
                is_auto_increment => 0
            };

            if($$field{default} eq "Auto Incr.")
            {
                $$parsed_field{is_auto_increment} = 1;
            }

            if($$field{constr} =~ /U/)
            {
                $$parsed_field{is_unique} = 1;
            }
            
            if($$field{constr} =~ /NN/)
            {
                $$parsed_field{is_nullable} = 0;
            }

            if($$field{figure} eq "Ellipse")
            {
                $$parsed_field{is_primary_key} = 1;
            }
            elsif($$field{figure} eq "TriangleUp")
            {
                $$parsed_field{is_foreign_key} = 1;
            }
            push $$result{$$table{key}}{fields}, $parsed_field;
        }
    }

    for my $link (@{$$parsed_input{linkDataArray}})
    {
        for my $field (@{$$result{$$link{from}}{fields}})
        {
            if($$field{name} eq $$link{fromPort})
            {
                $$field{fkey_ref} = $$link{to} . "." . $$link{toPort};
                last;
            }
        }
    }
    
    return to_json($result);
}

sub FromSchemaToWeb($)
{
    my ($json) = @_;

    my $result = {
        class => "go.GraphLinksModel",
        linkToPortIdProperty => "toPort",
        linkFromPortIdProperty => "fromPort",
        linkDataArray => [],
        nodeDataArray => []
    };

    my $input_hash = from_json($json);
    
    for my $key (keys %$input_hash)
    {
        my $node = {
            key => $$input_hash{$key}{name},
            loc => $$input_hash{$key}{loc},
            fields => [] 
        };

        for my $field (@{$$input_hash{$key}{fields}})
        {

            my @constrs_arr = ();
            if($$field{is_unique})
            {
                push @constrs_arr, "U"; 
            }
            if( ! $$field{is_nullable})
            {
                push @constrs_arr, "NN";
            }
    
            my $constr = "";
            if(scalar @constrs_arr)
            {
                $constr = join(', ', @constrs_arr);
            }   

            my $color = "#7FBA00";
            my $figure = "LineH";
            if($$field{is_primary_key})
            {
                $color = "#F25022";
                $figure = "Ellipse";
            }
            elsif($$field{is_foreign_key})
            {
                $color = "#225cf2";
                $figure = "TriangleUp";
                
                if(defined $$field{fkey_ref})
                {
                    my @fkey = split(/\./, $$field{fkey_ref});
                    push $$result{linkDataArray}, {to => $fkey[0], toPort => $fkey[1], from => $key, fromPort => $$field{name}};
                }

            }

            my $default = $$field{default_value};
            if( ! defined $default && $$field{is_auto_increment})
            {
                $default = "Auto Incr.";
            }

            push $$node{fields}, {
                    name => $$field{name},
                    type => $$field{data_type},
                    constr => $constr,
                    color => $color,
                    figure => $figure,
                    default => $default,
            };
        }
        push $$result{nodeDataArray}, $node;   
    }

    my $to_return = to_json($result);
    $to_return =~ s/'/\\'/g; #escape quotes

    return $to_return;
}

sub FromDDLToSchema($$)
{
    my ($ddl, $dialect) = @_;

    ASSERT(defined $ddl, "Missing DDL");
    ASSERT(defined $dialect, "Missing dialect");
    ASSERT($dialect eq 'SQLite' 
            || $dialect eq 'MySQL' 
            || $dialect eq 'PostgreSQL' 
            || $dialect eq 'SQLServer' 
            || $dialect eq 'Oracle'
        , "Unsupported dialect"
    );

    my $t = SQL::Translator->new;
    $t->parser($dialect) or die $t->error;
    $t->producer( \&produce ) or die $t->error;
    my $schema = $t->translate( \$ddl ) or die $t->error;

    return to_json($schema);
}

sub produce($) 
{
    my $tr     = shift;
    my $tables = {};
    my $schema = $tr->schema;
    
    for my $t ( $schema->get_tables )
    {
        my $table_name = $t->name;
        $$tables{$table_name} = {name => $table_name};

        my $fields = [];
        for my $f ($t->get_fields) 
        {
            push $fields, {
                name => $f->name,
                data_type => $f->data_type,
                default_value => $f->default_value,
                fkey_ref => $f->foreign_key_reference,
                is_auto_increment => $f->is_auto_increment,
                is_foreign_key => $f->is_foreign_key,
                is_nullable => $f->is_nullable,
                is_primary_key => $f->is_primary_key,
                is_unique => $f->is_unique,
            };
        }
        $$tables{$table_name}{fields} = $fields;
    }

    return $tables;
}

1;
