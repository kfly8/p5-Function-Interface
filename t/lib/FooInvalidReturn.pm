package FooInvalidReturn;
use Function::Interface::Impl qw(IFoo);
use Function::Return;
use Function::Parameters;

use Types::Standard -types;

fun foo() :Return(Str) {}

1;
