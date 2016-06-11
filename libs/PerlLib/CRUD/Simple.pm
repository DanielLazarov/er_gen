package PerlLib::CRUD::Simple;

use strict;

use HTML::Template;
use Data::Dumper;
use Scalar::Util;

use PerlLib::Errors::Errors;

our $lib_dir = '/usr/share/cleaning/libs';

sub generateTable($$)
{
    my ($app ,$params) = @_;

    ASSERT($$params{table});

    my $crud_schema = $$app{crud_schema}{$$params{table}};

    ASSERT($$crud_schema{view});
    ASSERT($$crud_schema{table});
    ASSERT($$crud_schema{unique_identifier_colname});
    ASSERT(defined $$crud_schema{can_create});
    ASSERT(defined $$crud_schema{can_update});
    ASSERT(defined $$crud_schema{can_delete});

    my $load_container = $$params{load_container} // 1;

    my $db_view = $$app{dbh}->quote_identifier($$crud_schema{view});

    my $template = HTML::Template->new(filename => "$lib_dir/PerlLib/CRUD/templates/table.tmpl");

    my $sth = $$app{dbh}->prepare("SELECT * FROM $db_view");
    $sth->execute();

    my $columns_ref = $$sth{NAME};
    my @columns;
    for my $i (@{$columns_ref})
    {
        if($i ne "unique_identifier")
        {
            my $th_value = $i;
            if($th_value =~ /_file$/)
            {
                $th_value =~ s/_..._file$//;
            }
            push @columns, {TH_VALUE => $th_value};
        }
    }

    my $tr_loop = [];

    while(my $row = $sth->fetchrow_arrayref())
    {
        my $tr = {
            CAN_CREATE_OR_UPDATE_TD => ($$crud_schema{can_create} || $$crud_schema{can_update}),
            CAN_UPDATE_TD => $$crud_schema{can_update},
            CAN_DELETE_TD => $$crud_schema{can_delete}
        };
        
        my $td_loop = [];
        my $is_first = 1;
        for(my $i = 0; $i < scalar @$row; $i++)
        {
            if($is_first)
            {
                $is_first = 0;
                $$tr{UNIQUE_IDENTIFIER} = $$row[$i];
                next;
            }

            my $td = {
                ALIGN_RIGHT_TD => Scalar::Util::looks_like_number($$row[$i]), 
                TD_VALUE => $$row[$i]
            };

            if($$columns_ref[$i] =~ /_file$/)
            {
                if($$columns_ref[$i] =~ /pdf_file$/)
                {
                    $$td{FILE_TYPE} = "application/pdf";
                }
                $$td{IS_FILE} = 1;
                $$td{FILE_PATH} = $$row[$i];
                $$td{TD_VALUE} = "Download";
                $$td{ALIGN_RIGHT_TD} = 0;
            }

            push $td_loop, $td;
        }
        $$tr{TD_LOOP} = $td_loop;

        push $tr_loop, $tr;
    }



    $template->param(
        CAN_CREATE_OR_UPDATE_TH => ($$crud_schema{can_create} || $$crud_schema{can_update}),
        CAN_CREATE_TH => $$crud_schema{can_create},
        CAN_DELETE_TH => $$crud_schema{can_delete},
        TH_LOOP => \@columns,
        TR_LOOP => $tr_loop,
        TABLE => $$crud_schema{table},
        TABLE_LABEL => $$crud_schema{table_label},
        LOAD_CONTAINER => $load_container
    );

    return $template->output();
}

sub generateForm($$)
{
    my ($app, $params) = @_;

    ASSERT($$params{table});
    ASSERT($$params{action});
    ASSERT($$params{action} eq 'create' || $$params{action} eq 'update');

    my $crud_schema = $$app{crud_schema}{$$params{table}};

    ASSERT(defined $crud_schema);
    TRACE("Schema: ", Dumper $crud_schema);

    my @fields_arr;

    my $default_row;
    if($$params{action} eq 'update')#UPDATE
    {
        ASSERT($$params{unique_identifier});
        
        my $quoted_table = $$app{dbh}->quote_identifier($$crud_schema{table});
        my $quoted_colname = $$app{dbh}->quote_identifier($$crud_schema{unique_identifier_colname});
        
        my $sth = $$app{dbh}->prepare("
            SELECT * FROM $quoted_table
            WHERE $quoted_colname = ?
        ");
        $sth->execute($$params{unique_identifier});
        ASSERT($sth->rows == 1);
        $default_row = $sth->fetchrow_hashref();
    }
    else#CREATE
    {
    }

    for my $coldef (@{$$crud_schema{column_definitions}})
    {
        my $field_settings = {
            name => $$coldef{name},
            label   => $$coldef{label},
            required => $$coldef{required},
            table => $$params{table}
        };

        if(defined $default_row)
        {
            $$field_settings{value} = $$default_row{$$coldef{name}};
        }

        TRACE("table", Dumper $coldef);
        if($$coldef{type} eq "text")
        {
            $$field_settings{IS_TEXT_INPUT} = 1;
        }
        elsif($$coldef{type} eq "number")
        {
            $$field_settings{IS_NUMBER_INPUT} = 1;
        }
        elsif($$coldef{type} eq "textarea")
        {
            $$field_settings{IS_TEXTAREA} = 1;
        }
        elsif($$coldef{type} eq "date")
        {
            $$field_settings{IS_DATE} = 1;
        }
        elsif($$coldef{type} eq "datetime")
        {
            $$field_settings{IS_DATETIME} = 1;
        }
        elsif($$coldef{type} eq "time")
        {
            $$field_settings{IS_TIME} = 1;
        }
        elsif($$coldef{type} eq "select")
        {
            ASSERT($$coldef{query});
            $$field_settings{IS_SELECT} = 1;
            my $field_sth = $$app{dbh}->prepare($$coldef{query});
            $field_sth->execute();

            $$field_settings{SELECT_OPTIONS_LOOP} = [];

            while(my $field_row = $field_sth->fetchrow_hashref)
            {
                push $$field_settings{SELECT_OPTIONS_LOOP}, $field_row;
            }
        }
        else
        {
            TRACE("Unsupported type", $$coldef{type});
            ASSERT(0, "Unsupported type");
        }

        push @fields_arr, $field_settings; 
    }

    my $template = HTML::Template->new(filename => "$lib_dir/PerlLib/CRUD/templates/form.tmpl");
    
    $template->param(
        FIELDS_LOOP => \@fields_arr,
        IS_CREATE => ($$params{action} eq 'create'),
        IS_UPDATE => ($$params{action} eq 'update'),
        UNIQUE_IDENTIFIER => $$params{unique_identifier},
        TABLE => $$params{table} 
    );


    return $template->output();
}

sub deleteEntry($$)
{
    my ($app, $params) = @_;

    ASSERT($$params{table});
    ASSERT($$params{unique_identifier});

    my $crud_schema = $$app{crud_schema}{$$params{table}};
    
    my $quoted_table = $$app{dbh}->quote_identifier($$crud_schema{table});
    my $quoted_colname = $$app{dbh}->quote_identifier($$crud_schema{unique_identifier_colname});

    my $sth = $$app{dbh}->prepare("
        UPDATE $quoted_table 
        SET is_deleted = TRUE
        WHERE $quoted_colname = ?
        RETURNING *
    ");
    $sth->execute($$params{unique_identifier});
    ASSERT($sth->rows == 1);
    my $row = $sth->fetchrow_hashref();

    return $row;
}

sub createEntry($$)
{
    my ($app, $params) = @_;

    ASSERT($$params{table});

    my $crud_schema = $$app{crud_schema}{$$params{table}};
    
    my $quoted_table = $$app{dbh}->quote_identifier($$crud_schema{table});
    
    my @columns;
    my @values;
    my @placeholders;
    for my $col (@{$$crud_schema{column_definitions}})
    {
        push @columns, $$app{dbh}->quote_identifier($$col{name}); 
        push @values, $$params{$$col{name}};
        push @placeholders, '?';
    }
    
    my $col_query = join(', ', @columns);
    my $placeholder_query = join(', ', @placeholders);

    my $sth = $$app{dbh}->prepare("
        INSERT INTO $quoted_table($col_query) 
        VALUES($placeholder_query)
        RETURNING *
    ");
    $sth->execute(@values);
    ASSERT($sth->rows == 1);
    my $row = $sth->fetchrow_hashref();

    return $row;
}

sub updateEntry($$)
{
    my ($app, $params) = @_;

    ASSERT($$params{table});
    ASSERT($$params{unique_identifier});

    my $crud_schema = $$app{crud_schema}{$$params{table}};

    my $quoted_table = $$app{dbh}->quote_identifier($$crud_schema{table});
    my $quoted_colname = $$app{dbh}->quote_identifier($$crud_schema{unique_identifier_colname});

    my @columns;
    my @values;
    for my $col (@{$$crud_schema{column_definitions}})
    {
        push @columns, $$app{dbh}->quote_identifier($$col{name});
        push @values, $$params{$$col{name}};
    }

    push @values, $$params{unique_identifier};
   
    my $col_query = join(' = ?, ', @columns);
    $col_query .= " = ?";
    my $sth = $$app{dbh}->prepare("
        UPDATE $quoted_table SET $col_query
        WHERE $quoted_colname = ? 
        RETURNING *
    ");
    $sth->execute(@values);
    ASSERT($sth->rows == 1);
    my $row = $sth->fetchrow_hashref();

    return $row;
}
1;
