package FooInvalidParams;
use Function::Interface::Impl qw(IFoo);
use Function::Return;
use Function::Parameters;

use Types::Standard -types;

fun foo(Str $a) :Return() {}

1;
