requires 'perl', '5.014004';
requires 'Function::Parameters', '2.000003';
requires 'Function::Return', '0.05';
requires 'PPR';
requires 'Keyword::Simple', '0.04';
requires 'Carp';
requires 'Class::Load';
requires 'Type::Tiny';
requires 'Import::Into';

on 'test' => sub {
    requires 'Test2::V0';
};
