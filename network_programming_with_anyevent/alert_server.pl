#!/usr/bin/perl

use strict;
use warnings;

# enviar para balinha@gmail.com
# 
# 
#
# To force the use of a specific event loop, just use it first like:
# 
# use Ev;

use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;

my $port = 44344;

$|++; # Auto-flush stdout please

# All our clients are belong to us
my ($add_cln, $rem_cln, $bcast_clns) = client_manager();


# Our listening server socket
my $server = tcp_server undef, $port, sub {
  my ($sock, $peer_host, $peer_port) = @_;
  my $cln_id = "$peer_host:$peer_port";
  
  # Fresh meat!
  print "New client: $cln_id\n";
  $bcast_clns->(sub {
    $_[0]->push_write("New buddy, mister: $cln_id\n");
  });
  
  my $handle = AnyEvent::Handle->new(
    fh => $sock,
    
    on_eof => sub {
      $rem_cln->($cln_id);
      
      $bcast_clns->(sub {
        $_[0]->push_write("Buddy doesn't like you anymore, mister: $cln_id\n");
      });
    }
  );
  
  # oh clousures, how I love thee
  my $read_line;
  $read_line = sub {
    my ($handle, $line) = @_;
    print "From $cln_id got line '$line'\n";
    
    $bcast_clns->(sub {
      my ($cln) = @_;
      
      $cln->push_write("$cln_id: $line\n") if $cln ne $handle;
    });
    
    # Thank you sir, can I have another?
    $handle->push_read( line => $read_line );
  };

  # Wait for a pick up line
  $handle->push_read( line => $read_line );
  
  # Made it!
  $add_cln->($cln_id => $handle);
};



# Wait for the end of the world
print "Waiting for ungrateful clients on $port...\n";
AnyEvent->condvar->recv;


























################
# Client manager

sub client_manager {
  my @clients;

  my $add_client = sub {
    push @clients, { id => $_[0], handle => $_[1] };
  };

  my $rem_client = sub {
    my $id = shift;
    @clients = grep { $_->{id} ne $id } @clients;
  };
  
  my $bcast_clients = sub {
    foreach my $cln (@clients) {
      $_[0]->($cln->{handle}, $cln->{id});
    }
  };

  return ($add_client, $rem_client, $bcast_clients);
}






























