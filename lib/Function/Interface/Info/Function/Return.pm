package Function::Interface::Info::Function::Return;

use v5.14.0;
use warnings;

our $VERSION = "0.01";

sub new {
    my ($class, %args) = @_;
    bless \%args => $class;
}

sub type() { $_[0]->{type} }

1;
