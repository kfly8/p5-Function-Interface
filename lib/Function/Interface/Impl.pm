package Function::Interface::Impl;

use v5.14.0;
use warnings;

our $VERSION = "0.02";

use Class::Load qw(load_class try_load_class);
use Scalar::Util qw(blessed);

my @CHECK;
my %CHECKED;
sub import {
    my $class = shift;
    my @interface_packages = @_;
    my ($pkg, $filename, $line) = caller;

    for my $ifpkg (@interface_packages) {
        push @CHECK => +{
            package           => $pkg,
            interface_package => $ifpkg,
            filename          => $filename,
            line              => $line,
        }
    }
}

sub CHECK {
    for (@CHECK) {
        my $pkg   = $_->{package};
        my $ifpkg = $_->{interface_package};
        my @fl    = ($_->{filename}, $_->{line});

        my ($ok, $e) = try_load_class($ifpkg);
        error($e, @fl) if !$ok;

        my $ifinfo = info_interface($ifpkg)
                  or error("cannot get interface info", @fl);

        for my $func_info (@{$ifinfo->functions}) {
            my $fname = $func_info->subname;
            my $def   = $func_info->definition;

            my $code = $pkg->can($fname)
                or error("function `$fname` is required. Interface: $def", @fl);

            my $pinfo = info_params($code)
                or error("cannot get function `$fname` parameters info. Interface: $def", @fl);
            my $rinfo = info_return($code)
                or error("cannot get function `$fname` return info. Interface: $def", @fl);

            check_params($func_info, $pinfo)
                or error("function `$fname` is invalid parameters. Interface: $def", @fl);
            check_return($func_info, $rinfo)
                or error("function `$fname` is invalid return. Interface: $def", @fl);
        }

        # for Types::Interface#ImplOf
        # see also `impl_of`
        $CHECKED{$pkg}{$ifpkg} = !!1;
    }
}

sub error {
    my ($msg, $filename, $line) = @_;
    die sprintf "implements error: %s at %s line %s\n\tdied", $msg, $filename, $line;
}

sub info_interface {
    my $interface_package = shift;
    load_class('Function::Interface');
    Function::Interface::info($interface_package)
}

sub info_params {
    my $code = shift;
    load_class('Function::Parameters');
    Function::Parameters::info($code)
}

sub info_return {
    my $code = shift;
    load_class('Function::Return');
    Function::Return::info($code)
}

sub check_params {
    my ($func_info, $pinfo) = @_;

    return unless $func_info->keyword eq $pinfo->keyword;

    for my $key (qw/positional_required positional_optional named_required named_optional/) {
        for my $i (0 .. $#{$func_info->$key}) {
            my $ifp = $func_info->$key->[$i];
            my $p = ($pinfo->$key)[$i];
            return unless check_param($ifp, $p);
        }
    }
    return !!1
}

sub check_param {
    my ($interface_param, $param) = @_;
    return $interface_param->type eq $param->type
        && $interface_param->name eq $param->name
}

sub check_return {
    my ($func_info, $rinfo) = @_;

    for my $i (0 .. $#{$func_info->return}) {
        my $ifr = $func_info->return->[$i];
        my $type = $rinfo->types->[$i];
        return unless $ifr->type eq $type;
    }
    return !!1;
}

sub impl_of {
    my ($package, $interface_package) = @_;
    $package = ref $package ? blessed($package) : $package;
    $CHECKED{$package}{$interface_package}
}

1;
__END__

=encoding utf-8

=head1 NAME

Function::Interface::Impl - implements interface

=head1 SYNOPSIS

    package Foo {
        use Function::Interface::Impl qw(IFoo);

        use Function::Parameters;
        use Function::Return;
        use Types::Standard -types;

        fun hello(Str $msg) :Return(Str) {
            return "HELLO $msg";
        }
    }

and declare interface class:

    package IFoo {
        use Function::Interface;
        use Types::Standard -types;

        fun hello(Str $msg) :Return(Str);
    }

=head1 DESCRIPTION

Function::Interface::Impl is for implementing interface.
At compile time, it checks whether it is implemented according to the interface.

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut

