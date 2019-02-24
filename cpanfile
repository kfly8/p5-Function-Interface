requires 'perl', '5.008001';

requires 'Function::Parameters';
requires 'Function::Return';

requires 'Carp';
requires 'Keyword::Simple';
requires 'PPR';

requires 'Class::Load';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

