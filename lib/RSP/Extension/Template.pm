package RSP::Extension::Template;

use strict;
use warnings;

use Template;
use Scalar::Util qw( blessed );

sub provide {
  my $class = shift;
  my $tx    = shift;
  return (
    'template' => sub {
      my $template = shift;
      my $templateData = shift;
      
      my $procstring;
      if ( blessed( $template ) ) {
        $procstring = $template->fullpath;
      } else {
        $procstring = \$template;
      }
      my $tt = Template->new( 
        INCLUDE_PATH => [ $tx->webroot ],
        ABSOLUTE     => 1,
        RECURSION => 1
      );
      my $buf;
      
      $tt->process($procstring, $templateData, \$buf) or warn $tt->error;
      return $buf;    
    }
  );
}

1;