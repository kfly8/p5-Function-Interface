package Function::Interface::Impl;

use v5.14.0;
use warnings;

our $VERSION = "0.03";

use Class::Load qw(load_class try_load_class is_class_loaded);
use Scalar::Util qw(blessed);
use Import::Into;

sub import {
    my $class = shift;
    my @interface_packages = @_;
    my ($pkg, $filename, $line) = caller;

    for (@interface_packages) {
        _register_check_list($pkg, $_, $filename, $line);
    }

    Function::Parameters->import::into($pkg);
    Function::Return->import::into($pkg);
}

our @CHECK_LIST;
my %IMPL_CHECKED;
CHECK {
    for (@CHECK_LIST) {
        assert_valid(@$_{qw/package interface_package filename line/});

        # for Function::Interface::Types#ImplOf
        $IMPL_CHECKED{$_->{package}}{$_->{interface_package}} = !!1;
    }
}

sub _register_check_list {
    my ($package, $interface_package, $filename, $line) = @_;

    push @CHECK_LIST => +{
        package           => $package,
        interface_package => $interface_package,
        filename          => $filename,
        line              => $line,
    }
}

sub assert_valid {
    my ($package, $interface_package, $filename, $line) = @_;
    my @fl = ($filename, $line);

    {
        my $ok = is_class_loaded($package);
        return _error("implements package is not loaded yet. required to use $package", @fl) if !$ok;
    }

    {
        my ($ok, $e) = try_load_class($interface_package);
        return _error("cannot load interface package: $e", @fl) if !$ok;
    }

    my $iinfo = info_interface($interface_package)
            or return _error("cannot get interface info", @fl);

    for my $ifunction_info (@{$iinfo->functions}) {
        my $fname = $ifunction_info->subname;
        my $def   = $ifunction_info->definition;

        my $code = $package->can($fname)
            or return _error("function `$fname` is required. Interface: $def", @fl);

        my $pinfo = info_params($code)
            or return _error("cannot get function `$fname` parameters info. Interface: $def", @fl);
        my $rinfo = info_return($code)
            or return _error("cannot get function `$fname` return info. Interface: $def", @fl);

        check_params($pinfo, $ifunction_info)
            or return _error("function `$fname` is invalid parameters. Interface: $def", @fl);
        check_return($rinfo, $ifunction_info)
            or return _error("function `$fname` is invalid return. Interface: $def", @fl);
    }
}

sub _error {
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


# XXX:
# We want to call CHECK in the following order:
# 1. Function::Return#CHECK (to get return info)
# 2. Function::Interface::Impl#CHECK (to check implements)
#
# CHECK is LIFO.
# So, it is necessary to load in the following order:
# 1. Function::Interface::Impl
# 2. Function::Return
#
# Because of this,
# Function::Interface::Impl doesn't use Function::Return, but does load_class.
sub info_return {
    my $code = shift;
    load_class('Function::Return');
    Function::Return::info($code)
}

sub check_params {
    my ($pinfo, $ifunction_info) = @_;

    return unless $ifunction_info->keyword eq $pinfo->keyword;

    my $params_count = 0;
    for my $key (qw/positional_required positional_optional named_required named_optional/) {
        my @params = $pinfo->$key;
        $params_count += @params;

        for my $i (0 .. $#{$ifunction_info->$key}) {
            my $ifp = $ifunction_info->$key->[$i];
            my $p = $params[$i];
            return unless check_param($p, $ifp);
        }
    }

    return unless $params_count == @{$ifunction_info->params};
    return !!1
}

sub check_param {
    my ($param, $iparam) = @_;
    return unless $param;
    return $iparam->type eq $param->type
        && $iparam->name eq $param->name
}

sub check_return {
    my ($rinfo, $ifunction_info) = @_;

    return unless @{$rinfo->types} == @{$ifunction_info->return};

    for my $i (0 .. $#{$ifunction_info->return}) {
        my $ifr = $ifunction_info->return->[$i];
        my $type = $rinfo->types->[$i];
        return unless $ifr->type eq $type;
    }
    return !!1;
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

Function::Interface::Impl - implements interface

=head1 SYNOPSIS

    package Foo {
        use Function::Interface::Impl qw(IFoo);
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

