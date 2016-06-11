package PerlLib::Security::Security;
use strict;

use DBI;
use Data::Dumper;
use Digest::SHA qw(sha256_hex);

use PerlLib::Security::Config;

use PerlLib::Errors::Errors;


sub createUser($$$)
{
    my ($app, $username, $password) = @_;

    ASSERT(defined $app, "Undefined app");
    ASSERT(defined $username, "Undefined username");
    ASSERT(defined $password, "Undefined password");

    my $salt = sha256_hex(rand . localtime . rand);
    my $password_sha = sha256_hex($salt . $password . $$PerlLib::Security::Config::CONSTS{PEPPER});
    my $sth = $$app{dbh}->prepare(q{
        INSERT INTO sys_users(username, password, salt)
        VALUES(?, ?, ?)
    });
    $sth->execute($username, $password_sha, $salt);
    ASSERT($sth->rows == 1);

    return ;
}

sub checkLogin($$$)
{
    my ($app, $username, $password) = @_;

    
    ASSERT_USER(defined $username, "No username specified", "S01"); 
    ASSERT_USER(defined $password, "No password specified", "S02");

    my $sth = $$app{dbh}->prepare(q{
        SELECT *
        FROM sys_users 
        WHERE username = ?
    });
    $sth->execute($username);
    ASSERT($sth->rows <= 1);

    ASSERT_USER($sth->rows == 1, "Incorrect Username or Password", "S03");
    my $row = $sth->fetchrow_hashref;

    ASSERT_USER(sha256_hex($$row{salt} . $password . $$PerlLib::Security::Config::CONSTS{PEPPER}) eq $$row{password}, "Incorrect Username or Password", "S03");

    return $row;
}

sub createSession($$;$)
{
    my ($app, $sys_user_id, $expiration_min) = @_;

    $expiration_min = $expiration_min // $$PerlLib::Security::Config::CONSTS{SESSION_EXPIRATION_MINUTES};

    my $sth = $$app{dbh}->prepare(q{
        INSERT INTO sys_users_sessions(sys_user_id, expires_at)
        VALUES(?, now() + ?::interval) RETURNING *
    });
    $sth->execute($sys_user_id, "$expiration_min minutes");
    ASSERT($sth->rows == 1);
    my $row = $sth->fetchrow_hashref;

    return $$row{session_id};
}

sub refreshSessionToken($$)
{
    my ($app, $session_token) = @_;

    my $sth = $$app{dbh}->prepare(q{
        UPDATE sys_users_sessions 
        SET session_id = md5(random()::text || now()::text || random()::text)
        WHERE session_id = ?
        RETURNING *
    });
    $sth->execute($session_token);
    ASSERT($sth->rows == 1);
    
    my $result_row = $sth->fetchrow_hashref;

    return $$result_row{session_id};
}

sub checkSession($$$)
{
    my ($app, $username, $session_token) = @_;
    
    my $sth = $$app{dbh}->prepare(q{
        SELECT *
        FROM sys_users_sessions SUS
            JOIN sys_users SU ON SUS.sys_user_id = SU.id
        WHERE SU.username = ?
          AND SUS.session_id = ?
          AND (SUS.expires_at IS NULL OR SUS.expires_at > now())
    });
    $sth->execute($username, $session_token);
    
    if($sth->rows > 0)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

sub expireSession($$)
{
    my ($app, $session_token) = @_;

    my $sth = $$app{dbh}->prepare(q{
        UPDATE sys_users_sessions
            SET expires_at = now() 
        WHERE session_id = ?
    });
    $sth->execute($session_token);
    ASSERT($sth->rows == 1);

    return $session_token;
}

1;

