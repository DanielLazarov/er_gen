#!/bin/bash
aptitude update
aptitude install apache2 libapache2-mod-perl2 libdbi-perl libtry-tiny-perl libhtml-template-perl libdbd-pg-perl 

#psql 9.4 repo
#add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main"
#wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
#  sudo apt-key add -
#aptitude update
#aptitude install postgresql-9.4

