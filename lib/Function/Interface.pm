package Function::Interface;

use v5.14.0;
use warnings;

our $VERSION = "0.03";

use Carp qw(croak);
use Keyword::Simple;
use PPR;

use Function::Interface::Info;
use Function::Interface::Info::Function;
use Function::Interface::Info::Function::Param;
use Function::Interface::Info::Function::ReturnParam;

sub import {
    my $class = shift;
    my %args = @_;

    my $pkg = $args{pkg} ? $args{pkg} : caller;

    Keyword::Simple::define 'fun' => _define_interface($pkg, 'fun');
    Keyword::Simple::define 'method' => _define_interface($pkg, 'method');
}

sub unimport {
    Keyword::Simple::undefine 'fun';
    Keyword::Simple::undefine 'method';
}

sub _define_interface {
    my ($pkg, $keyword) = @_;

    return sub {
        my $ref = shift;

        my $match = _assert_valid_interface($$ref);
        my $src = _render_src($pkg, $keyword, $match);

        substr($$ref, 0, length $match->{statement}) = $src;
    }
}

sub _render_src {
    my ($pkg, $keyword, $match) = @_;

    my $src = <<"```";
BEGIN {
    Function::Interface::_register_info({
        package => '$pkg',
        keyword => '$keyword',
        subname => '$match->{subname}',
        params  => [ @{[ join ',', map {
            my $named    = $_->{named} ? 1 : 0;
            my $optional = $_->{optional} ? 1 : 0;
            qq!{ type => $_->{type}, name => '$_->{name}', named => $named, optional => $optional }!
        } @{$match->{params}} ]} ],
        return  => [ @{[ join ',', @{$match->{return}}] } ],
    });
}
```
    return $src;
}

our %metadata;
sub _register_info {
    my ($args) = @_;

    push @{$metadata{$args->{package}}} => +{
        subname => $args->{subname},
        keyword => $args->{keyword},
        params  => $args->{params},
        return  => $args->{return},
    };
}

sub info {
    my ($interface_package) = @_;
    my $info = $metadata{$interface_package} or return undef;

    Function::Interface::Info->new(
        package   => $interface_package,
        functions => [ map {
            Function::Interface::Info::Function->new(
                subname => $_->{subname},
                keyword => $_->{keyword},
                params  => [ map { _make_function_param($_) } @{$_->{params}} ],
                return  => [ map { _make_function_return_param($_) } @{$_->{return}} ],
            )
        } @{$info}],
    );
}

sub _make_function_param {
    my $param = shift;
    Function::Interface::Info::Function::Param->new(
        type     => $param->{type},
        name     => $param->{name},
        named    => $param->{named},
        optional => $param->{optional},
    )
}

sub _make_function_return_param {
    my $type = shift;
    Function::Interface::Info::Function::ReturnParam->new(
        type => $type,
    )
}

sub _assert_valid_interface {
    my $src = shift;

    $src =~ m{
        \A
        (?<statement>
            (?&PerlOWS) (?<subname>(?&PerlIdentifier))
            (?&PerlOWS) \((?<params>.*?)\)
            (?&PerlOWS) :Return\((?<return>.*?)\)
            ;
        )
        $PPR::GRAMMAR
    }sx or croak "invalid interface";

    my %match;
    $match{statement} = $+{statement};
    $match{subname} = $+{subname};
    $match{params}  = $+{params} ? _assert_valid_interface_params($+{params}) : [];
    $match{return}  = $+{return} ? _assert_valid_interface_return($+{return}) : [];

    return \%match;
}

$Function::Interface::GRAMMAR = qr{
    (?(DEFINE)
        (?<PerlType>
            (?&PerlIdentifier)
            (?: \s* \[
                \s* (?&PerlTypeParameter) \s*
                (?: , \s* (?&PerlTypeParameter) \s* )*+
            \] )?
        )

        (?<PerlTypeParameter>
            (?&PerlString)|(?&PerlVariable)|(?&PerlType)
        )
    )

    $PPR::GRAMMAR
}x;

sub _assert_valid_interface_params {
    my $src = shift;

    my @list = grep { defined } $src =~ m{
        ((?&PerlType))     \s*
        (:?) # named       \s*
        ((?&PerlVariable)) \s*
        (=?) # optional

        $Function::Interface::GRAMMAR
    }xg;

    my @params;
    while (my ($type, $named, $name, $optional) = splice @list, 0, 4) {
        push @params => {
            type     => $type,
            named    => !!$named,
            name     => $name,
            optional => !!$optional,
        }
    }

    my $regex = join '\s*,\s*', map {
        quotemeta sprintf('%s %s%s%s',
            $_->{type},
            $_->{named} ? ':' : '',
            $_->{name},
            $_->{optional} ? '=' : '',
        )
    } @params;

    croak "invalid interface params: $src"
        unless $src =~ m{ \A \s* $regex \s* \z }x;

    return \@params;
}

sub _assert_valid_interface_return {
    my $src = shift;

    my @list = grep { defined } $src =~ m{
        ((?&PerlType))
        $Function::Interface::GRAMMAR
    }xg;

    croak "invalid interface return: $src. It should be TYPELIST."
        unless $src =~ m{
            \A \s* @{[join '\s*,\s*', map { quotemeta $_ } @list]} \s* \z
        }x;

    return \@list;
}

1;
__END__

=encoding utf-8

=head1 NAME

Function::Interface - specify type constraints of subroutines

=head1 SYNOPSIS

    package IFoo {
        use Function::Interface;
        use Types::Standard -types;

        fun hello(Str $msg) :Return(Str);
    }

and implements interface class:

    package Foo {
        use Function::Interface::Impl qw(IFoo);

        use Function::Parameters;
        use Function::Return;
        use Types::Standard -types;

        fun hello(Str $msg) :Return(Str) {
            return "HELLO $msg";
        }
    }


=head1 DESCRIPTION

Function::Interface provides Interface like Java and checks the arguments and return type of the function at compile time.

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut

