use Test2::V0;

use Function::Interface;
use Types::Standard -types;

fun foo() :Return();
fun bar(Str $msg) :Return(Int);
method baz() :Return();

subtest 'basic' => sub {
    my $info = Function::Interface::info __PACKAGE__;

    is @{$info}, 3;

    subtest 'foo' => sub {
        my $i = $info->[0];
        is $i->subname, 'foo';
        ok !$i->is_method, 'fun';
        is $i->args, [];
        is $i->returns->list, [];
    };

    subtest 'bar' => sub {
        my $i = $info->[1];
        is $i->subname, 'bar';
        ok !$i->is_method, 'fun';

        is @{$i->args}, 1;
        isa_ok $i->args->[0], 'Sub::Meta::Param';
        ok $i->args->[0]->type eq Str;
        is $i->args->[0]->name, '$msg';

        isa_ok $i->returns, 'Sub::Meta::Returns';
        ok $i->returns->list->[0], Int;
    };

    subtest 'baz' => sub {
        my $i = $info->[2];
        is $i->subname, 'baz';
        ok $i->is_method, 'method';
        is $i->args, [];
        is $i->returns->list, [];
    };
};

subtest 'empty' => sub {
    my $info = Function::Interface::info 'Hoge';
    is $info, undef;
};

done_testing;

