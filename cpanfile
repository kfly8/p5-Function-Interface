requires 'perl', '5.014004';
requires 'Function::Parameters', '2.000003';
requires 'Function::Return', '0.07';
requires 'PPR';
requires 'Keyword::Simple', '0.04';
requires 'Carp';
requires 'Class::Load';
requires 'Type::Tiny', '1.000000';
requires 'Import::Into';

on 'test' => sub {
    requires 'Test2::V0', '0.000135';
    requires 'Module::Build::Tiny', '0.035';
};
