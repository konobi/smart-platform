#    This file is part of the RSP.
#
#    The RSP is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    The RSP is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with the RSP.  If not, see <http://www.gnu.org/licenses/>.

## Ideas from:
## http://www.stonehenge.com/merlyn/WebTechniques/col34.listing.txt

package RSP::Server;

use RSP;

use POSIX;
use IO::File;
use HTTP::Status;
use HTTP::Daemon;

our $VERSION = '3.00';

{
  no warnings 'redefine';
  sub HTTP::Daemon::product_tokens {
    return join("/", __PACKAGE__, $RSP::VERSION);
  }
}

sub start {
  $0 = HTTP::Daemon->product_tokens();
  setup_signals();
  run();
}

sub stop {
  my $PIDFILE = RSP->conf->server->pidfile;
  my $fh = IO::File->new( $PIDFILE );
  my $pid = $fh->getline;
  $fh->close;
  if ( kill 15, $pid ) {
    unlink $PIDFILE;
  } else {
    warn "Couldn't kill proces $pid\n";
  }
}

sub handle_one_connection {
  my $c = shift;
  #my $r = $c->get_request;
  my $this_conn = 0;
  eval {
    my $notimeout;
    local $SIG{ALRM} = sub {
      print "timeout exceded\n";
      if ($notimeout) { die "alarm"; }
    };
    $notimeout = 1;
    my $timeout = RSP->conf->server->connection_timeout;
    alarm($timeout);
    while( my $r = $c->get_request ) {    
      alarm(120);
      $notimeout = 0;
      $this_conn++;    
      my $response = eval { RSP->handle( $r ) };
      if ($@) {
        $c->send_error(RC_INTERNAL_SERVER_ERROR, $@);
      } else {
        if ( $this_conn == RSP->conf->server->max_requests_per_client) {
          $response->header('Connection','close');
        }
        $c->send_response( $response );      
        $notimeout = 1;
        if ($response->header('Connection') && $response->header('Connection') =~ /close/i) {
          last;
        }
      }
    } 
  };
  if ($@) {
    print $@;
  }
  alarm(0);
  $c->close;
}

sub run {
  my %kids;

  my %opts = (
    Reuse => 1,
    ReuseAddr => 1
  );

  my $CONFIG = RSP->config;
  my $server_conf = RSP->conf->server;
  my $PIDFILE = $server_conf->pidfile;

  if ( fork() ) {
    print "Forked daemon\n";
    exit;
  }
  
  my $master = HTTP::Daemon->new( %{ $CONFIG->{daemon} } )
    or die "Cannot create master: $!";

  my $fh = IO::File->new($PIDFILE, ">");
  if (!$fh) {
    die "could not open $PIDFILE: $!";
  } else {
    $fh->print($$);
    $fh->close;
  }

  if ( $server_conf->user ) {
   {
      my ($name,$passwd,$gid,$members) = getgrnam( $server_conf->group );
      if ($gid) {
        POSIX::setgid( $gid );
        if ($!) { warn "setgid: $!" }
      } else {
        die "unknown group ".$server_conf->group;
      }
   }
    {
      my ($name,$passwd,$uid,$gid, $quota,$comment,$gcos,$dir,$shell,$expire) = getpwnam( $server_conf->user );
      if ($uid) {
        POSIX::setuid( $uid );
	if ($!) { warn "setuid: $!" }
      } else {
        die "unknown user ".$server_conf->user;
      }
   }

  }


  for (1..$server_conf->max_children) {
    $kids{&fork_a_slave($master)} = "slave";
  }
  {                             # forever:
    my $pid = wait;
    my $was = delete ($kids{$pid}) || "?unknown?";
    if ($was eq "slave") {      # oops, lost a slave
      sleep 1;                  # don't replace it right away (avoid thrash)
      $kids{&fork_a_slave($master)} = "slave";
    }
  } continue { redo };          # semicolon for cperl-mode
  

}

sub setup_signals {             # return void
  setpgrp;                      # I *am* the leader
  $SIG{HUP} = $SIG{INT} = $SIG{TERM} = sub {
    my $sig = shift;
    $SIG{$sig} = 'IGNORE';
    kill $sig, 0;               # death to all-comers
    exit;
  };
}

sub fork_a_slave {              # return int (pid)
  my $master = shift;           # HTTP::Daemon

  my $pid;
  defined ($pid = fork) or die "Cannot fork: $!";
  &child_does($master) unless $pid;
  $pid;
}

sub child_does {                # return void
  my $master = shift;           # HTTP::Daemon

  my $did = 0;                  # processed count

  my $server_config = RSP->config;
  {
    flock($master, 2);          # LOCK_EX
    my $slave = $master->accept or die "accept: $!";
    flock($master, 8);          # LOCK_UN
    my @start_times = (times, time);
    $slave->autoflush(1);
    handle_one_connection($slave); # closes $slave at right time
  } continue { redo if ++$did < $server_config->max_requests_per_child };
  exit 0;
}


1;
