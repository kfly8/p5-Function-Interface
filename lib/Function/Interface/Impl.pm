package Function::Interface::Impl;

use v5.14.0;
use warnings;

our $VERSION = "0.06";

use Class::Load qw(try_load_class is_class_loaded);
use Scalar::Util qw(blessed);
use B::Hooks::EndOfScope;

use Function::Interface;
use Sub::Meta::Library;
use Import::Into;

my %IMPL_CHECKED;

our $ERROR_FILENAME;
our$ERROR_LINE;
sub _croak {
    my ($msg) = @_;
    require Carp;
    @_ = sprintf "implements error: %s at %s line %s\n\tdied", $msg, $ERROR_FILENAME, $ERROR_LINE;
    goto \&Carp::croak;
}

sub import {
    my $class = shift;
    my @interface_packages = @_;
    my ($impl_package, $filename, $line) = caller;

    Function::Parameters->import::into($impl_package);
    Function::Return->import::into($impl_package);

    on_scope_end {
        local $ERROR_FILENAME = $filename;
        local $ERROR_LINE = $line;

        for my $interface_package (@interface_packages) {
            $class->assert_valid($impl_package, $interface_package);

            # for Function::Interface::Types#ImplOf
            $IMPL_CHECKED{$interface_package}{$interface_package} = !!1;
        }
    }
}

sub assert_valid {
    my $class = shift;
    my ($package, $interface_package) = @_;

    {
        my $ok = is_class_loaded($package);
        _croak("implements package is not loaded yet. required to use $package") if !$ok;
    }

    {
        my ($ok, $e) = try_load_class($interface_package);
        _croak("cannot load interface package: $e") if !$ok;
    }

    my $interface_info = Function::Interface::info($interface_package)
            or _croak("cannot get interface info");

    for my $interface_submeta (@{$interface_info}) {
        my $subname = $interface_submeta->subname;
        my $code = $package->can($subname)
            or _croak("function `$subname` is required.");

        my $impl_submeta = Sub::Meta::Library->get($code)
            or _croak("cannot get function `$subname` info.");

        $interface_submeta->is_same_interface($impl_submeta)
            or _croak("function `$subname` is invalid interface.");
    }
}

sub impl_of {
    my ($package, $interface_package) = @_;
    $package = ref $package ? blessed($package) : $package;
    $IMPL_CHECKED{$package}{$interface_package}
}

1;
__END__

=encoding utf-8

=head1 NAME

Function::Interface::Impl - implements interface package

=head1 SYNOPSIS

Implements the interface package C<IFoo>:

    package Foo {
        use Function::Interface::Impl qw(IFoo);
        use Function::Parameters;
        use Function::Return;
        use Types::Standard -types;

        fun hello(Str $msg) :Return(Str) {
            return "HELLO $msg";
        }

        fun add(Int $a, Int $b) :Return(Int) {
            return $a + $b;
        }
    }

=head1 DESCRIPTION

Function::Interface::Impl is for implementing interface package.
This module checks if the abstract functions are implemented at B<compile time>.

=head1 METHODS

=head2 assert_valid

check if the interface package is implemented, otherwise die.

=head2 impl_of($package, $interface_package)

check if specified package is an implementation of specified interface package.

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut

