use 5.008008;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'System::Timeout',
    VERSION_FROM      => 'lib/System/Timeout.pm', 
    EXE_FILES => [ "bin/timeout" ],
    PREREQ_PM         => {}, 
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/System/Timeout.pm', 
       AUTHOR         => 'ChenGang <yikuyiku.com@gmail.com>') : ()),
);
