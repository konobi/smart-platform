package RSP::Transaction::Mojo::HostMap;

use strict;
use warnings;

sub firstdir {
  my $class = shift;
  my $req   = shift;
  my $parts = $req->url->path->parts;
  my $host = shift @$parts;
  
  $req->url->path->parts( @$parts );
  
  return $host;
}

sub hostname {
  my $class = shift;
  my $req  = shift;
  
  # XXX - if $req->headers->host is called in an array context it returns an arrayref
  return $class->strip_hostname( scalar($req->headers->host) );
}

##
## strips the port number of a hostname, if there is one
##
sub strip_hostname {
  my $self = shift;
  my $host = shift || die "no hostname";
  $host =~ s/:.+$//;
  return $host;
}


1;
