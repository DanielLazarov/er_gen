package ERDiag::WebViews::General;

use strict;

use HTML::Template;
use PerlLib::Errors::Errors;


sub loginPage($)
{
    my ($app) = @_;

    my $template = HTML::Template->new(filename => "/usr/share/er-diag/er-web/templates/login_page.tmpl");

    return $template->output();
}

sub homePage($)
{
    my ($app) = @_;

    my $template = HTML::Template->new(filename => "/usr/share/er-diag/er-web/templates/home_page.tmpl");

    my $username = $$app{cgi_obj}->cookie('USERNAME');
    if( ! defined $username)
    {
        $username = $$app{cgi}{username};
    }
    ASSERT(defined $username && $username ne "");

    $template->param(
        USERNAME => $username,
        HOME_FULL_TOP => 1,
        HOME_FULL_BOTTOM => 1,
        LOGOUT => $ERDiag::Config::Config::REQUIRE_LOGIN
    );
    
    return $template->output();
}

sub homePageAjax($)
{
    my ($app) = @_;

    my $template = HTML::Template->new(filename => "/usr/share/er-diag/er-web/templates/home_page.tmpl");

    return $template->output();
}


1;
