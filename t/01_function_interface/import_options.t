use Test2::V0;

use Function::Interface pkg => 'MyTest';
fun foo() :Return();

my $info = Function::Interface::info 'MyTest';
ok $info;

done_testing;
