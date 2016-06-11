#!/usr/bin/perl -w

binmode (STDIN, ":utf8");
binmode (STDOUT, ":utf8");
binmode (STDERR, ":utf8");

use ERDiag::WebHandler::WebHandler;
ERDiag::WebHandler::WebHandler->handle();


1;
