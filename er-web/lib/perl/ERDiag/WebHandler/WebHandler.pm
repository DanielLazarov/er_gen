package ERDiag::WebHandler::WebHandler;

use strict;

use CGI qw(:standart);
use DBI;
use Try::Tiny;
use Data::Dumper;
use HTML::Template;

use PerlLib::Errors::Errors;
use PerlLib::Security::Security;

use ERDiag::Config::Config;

use ERDiag::WebViews::General;
use ERDiag::WebActions::General;

sub handle($)
{
    my ($class) = @_;

    #dbh
    my $dbh = DBI->connect("DBI:Pg:dbname=$ERDiag::Config::Config::DB_NAME;host=$ERDiag::Config::Config::DB_HOST;port=$ERDiag::Config::Config::DB_PORT", "$ERDiag::Config::Config::DB_USER", "$ERDiag::Config::Config::DB_PASSWORD", {RaiseError => 1, AutoCommit => 0});
    $dbh->{pg_enable_utf8} = 1;    
    $dbh->rollback();
    
    #cgi
    my ($cgi, $cgi_obj) = handleCGIParams();
    
    Handler(bless {dbh => $dbh, cgi => $cgi, cgi_obj => $cgi_obj}, $class)
}

sub handleCGIParams()
{
    my $params;

    my $cgi = CGI->new();                    
    my @param_names = $cgi->param; 

    foreach my $p_name(@param_names)
    {
        if($cgi->param($p_name) eq "")
        {
            $$params{$p_name} = undef;
        }
        else
        {
            $$params{$p_name} = $cgi->param($p_name);
        }
    }
    TRACE("Request Params", Dumper $params);

    return ($params, $cgi);
}

sub Handler($)
{
    my($self) = @_;
    
    try
    {
        my $sess_id = $$self{cgi_obj}->cookie("SESSID");
        my $username = $$self{cgi_obj}->cookie("USERNAME");
        
        if($sess_id && $username)#Defined SESSID and USERNAME
        {
            #Check Session
            if(PerlLib::Security::Security::checkSession($self, $username, $sess_id))#Correct active session
            { 
                if($ERDiag::Config::Config::REQUIRE_LOGIN || $username eq "anon")
                {
                    if( ! defined $$self{cgi}{view})#First GET with correct active session: skip login screen
                    {
                        $$self{cgi}{action} = undef;
                        $$self{cgi}{view} = 'home_page';
                        $sess_id = PerlLib::Security::Security::refreshSessionToken($self, $sess_id); 
                    }
                    elsif( defined $$self{cgi}{view} && $$self{cgi}{view} eq "login_page" 
                    && defined $$self{cgi}{action} && $$self{cgi}{action} eq "logout") #Logout button
                    {
                        $self->Logout($sess_id);
                        $$self{cgi}{action} = undef;
                        $sess_id = undef;
                        $username = undef;
                    }
                    else #Everything is fine, refresh session_id
                    {
                        $sess_id = PerlLib::Security::Security::refreshSessionToken($self, $sess_id); 
                    }
                }
                elsif($username ne "anon")
                {
                    $self->Logout($sess_id);
                    $sess_id = undef;
                    $username = "anon";
                    $$self{cgi}{username} = $username;
                    $$self{cgi}{action} = undef;
                    $$self{cgi}{view} = 'home_page';
                    $sess_id = $self->Login();

                }
            }
            else #Invalid or expired session, Send login screen with error
            {
                $$self{cgi}{action} = "login";
                $$self{cgi}{view} = "login_page";
                $$self{cgi}{expired_session} = 1;
                ASSERT_USER(0, "Session expired, please Log in");
            }
        }
        else#No SESSID
        {
            if(defined $$self{cgi}{action} && defined $$self{cgi}{view} && $$self{cgi}{action} eq "login" && $$self{cgi}{view} eq "home_page")
            {#Login action
                if( ! $ERDiag::Config::Config::REQUIRE_LOGIN)
                {
                    $$self{cgi}{action} = undef;
                    $sess_id = undef;
                    $username = undef;
                }

                $username = $$self{cgi}{username};

                if($username eq "anon")
                {
                    ASSERT_USER(0, "Incorrect Username or Password", "S03");
                }

                $sess_id = $self->Login();
            }
            else
            {#First GET without session
                if($ERDiag::Config::Config::REQUIRE_LOGIN)
                {
                    $$self{cgi}{action} = undef;
                    $$self{cgi}{view} = 'login_page';
                }
                else
                {
                    $username = "anon";
                    $$self{cgi}{username} = $username;
                    $$self{cgi}{action} = undef;
                    $$self{cgi}{view} = 'home_page';
                    $sess_id = $self->Login();
                }
            }
        }
       
        my $sessid_cookie;
        my $username_cookie; 
        if(defined $sess_id && $sess_id)
        {
            ASSERT(defined $username && $username ne "");

            $sessid_cookie = $$self{cgi_obj}->cookie(-name => 'SESSID', -value => $sess_id);
            $username_cookie = $$self{cgi_obj}->cookie(-name => 'USERNAME', -value => $username);
        }
        else
        {
            $sessid_cookie = $$self{cgi_obj}->cookie(-name => 'SESSID', -value => '', -expires => '-1d');
            $username_cookie = $$self{cgi_obj}->cookie(-name => 'USERNAME', -value => '', -expires => '-1d');
        }

        my $action_result = $self->Action();#TODO ASSERT HREF format.
	    my $view_result = $self->View($action_result);
        
        $$self{dbh}->commit;
      
        if($$self{cgi}{file_type})
        {
            print $$self{cgi_obj}->header(
                -type    => $$self{cgi}{file_type},
                -cookie  => [$sessid_cookie, $username_cookie]
            );
        }
        else
        {
            print $$self{cgi_obj}->header(
                -type    => 'text/html',
                -charset => 'utf-8',
                -cookie  => [$sessid_cookie, $username_cookie]
            );
        }  
        if(ref $action_result && $$action_result{success_msg})
        {
            my $success_template = HTML::Template->new(filename => "/usr/share/cleaning/cleaning-web/templates/success.tmpl");
            $success_template->param(MSG => $$action_result{success_msg});
            print $success_template->output();
        }

        if($$self{cgi}{file_type})
        {
            binmode (STDOUT, ":raw");
            print $view_result;
            binmode (STDOUT, ":utf8");
        }
        else
        {
            print $view_result;
        }
    }
    catch
    {
        my $err = shift;
        
        $$self{dbh}->rollback;

        my $template;
        if($$self{cgi}{action} eq "login")
        {
            my $sessid_cookie = $$self{cgi_obj}->cookie(-name => 'SESSID', -value => '', -expires => '-1d');
            my $username_cookie = $$self{cgi_obj}->cookie(-name => 'USERNAME', -value => '', -expires => '-1d');

            print $$self{cgi_obj}->header(
                -type    => 'text/html',
                -charset => 'utf-8',
                -cookie  => [$sessid_cookie, $username_cookie],
            );

            if($$self{cgi}{expired_session})
            {
                $template = HTML::Template->new(filename => "/usr/share/er-diag/er-web/templates/session_error.tmpl");
            }
            else
            {
                $template = HTML::Template->new(filename => "/usr/share/er-diag/er-web/templates/login_page.tmpl");
                $template->param(ERR => 1);
            }
        }
        else
        {
            print CGI::header('text/html; charset=utf-8');
            $template = HTML::Template->new(filename => '/usr/share/er-diag/er-web/templates/error.tmpl');
        }

        if($err->isa("userError"))
        {
            TRACE("UserError", $$err{msg} . " " . $$err{code});
            $template->param(MSG => $$err{msg}, CODE => $$err{code});
        }
        elsif($err->isa("peerError"))
        {
            TRACE("PeerError", $$err{msg} . " " . $$err{code});
            $template->param(MSG => "Operation Failed", CODE => "CL01");
        }
        elsif($err->isa("sysError"))
        {
            TRACE("SystemError", $$err{msg} . " " . $$err{code});
            $template->param(MSG => "Application Error", CODE => "CL02");
        }
        else
        {
            TRACE("UnknownError", Dumper $err);
            $template->param(MSG => "Application Error", CODE => "CL02");
        }

        print $template->output;
    };
}

sub Action($)
{
    my($self) = @_;

    my $actions_map = {
        login => \&NoOp,
    };

    if(defined $$self{cgi}{action})
    {
        if(exists $$actions_map{$$self{cgi}{action}})
        {
            return $$actions_map{$$self{cgi}{action}}->($self);
        }
        else
        {
            ASSERT_PEER(0, "Not existing action", "CL03");
        }
    }
}

sub View($)
{
    my($self) = @_;

    my $views_map = {
        login_page => \&ERDiag::WebViews::General::loginPage,
        home_page => \&ERDiag::WebViews::General::homePage,
        home_page_ajax => \&ERDiag::WebViews::General::homePageAjax,
        load_schema => \&ERDiag::WebViews::Schemas::LoadSchema,
    };

    if(defined $$self{cgi}{view})
    {
        if(exists $$views_map{$$self{cgi}{view}})
        {
            return $$views_map{$$self{cgi}{view}}->($self);
        }
        else
        {
            ASSERT_PEER(0, "Not existing view", "CL04");
        }
    }
    else
    {
        return $$views_map{login_page}->($self);
    }
}

sub NoOp($)
{
    my ($self) = @_;
}

sub Login($)
{
    my($self) = @_;

    my $user_row;
    if($ERDiag::Config::Config::REQUIRE_LOGIN)
    {
        $user_row = PerlLib::Security::Security::checkLogin($self, $$self{cgi}{username}, $$self{cgi}{password});
        return PerlLib::Security::Security::createSession($self, $$user_row{id});#1 Day session expire by default
    }
    else
    {
        $user_row = PerlLib::Security::Security::checkLogin($self, "anon", "password");
        return PerlLib::Security::Security::createSession($self, $$user_row{id}, 60 * 24 * 365);#1 year session expiration
    }
}

sub Logout($$)
{
    my ($self, $sess_id) = @_;
    
    my $ended_sess_id = PerlLib::Security::Security::expireSession($self, $sess_id);
    ASSERT(defined $ended_sess_id);
}

1;
