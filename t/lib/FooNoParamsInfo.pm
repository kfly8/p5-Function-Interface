package FooNoParamsInfo;
use Function::Interface::Impl qw(IFoo);
use Function::Return;

sub foo :Return() {}

1;
