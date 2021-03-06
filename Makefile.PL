use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'RSP',
  VERSION_FROM => 'lib/RSP.pm',
  EXE_FILES => ['bin/rsp','bin/rspkeymanagerd', 'bin/clonewatcher'],
  MIN_PERL_VERSION => '5.10.0', # code uses 5.10 features, so require it as a minimum
  PREREQ_PM => {
      'Net::Stomp'          => 0,
      'DBI'                 => 0,
      'SQL::Abstract'       => 0,
      'Set::Object'         => 0,
      'Imager'              => 0,
      'Application::Config' => 0,
      'Mojo'                => '0.999910',
      'MIME::Types'         => 0,
      'Hash::Merge::Simple' => 0,
      'Digest::MD5'         => 0,
      'Digest::SHA1'        => 0,
      'Digest::HMAC_SHA1'   => 0,
      'JSON::XS'            => 0,
      'Scalar::Util'        => 0,
      'JavaScript'          => 0,
      'Module::Load'        => 0,
      'LWPx::ParanoidAgent' => 0,
      'Cache::Memcached::Fast' => 0,
      'Net::OpenID::Consumer' => 0,
      'Class::Accessor::Chained' => 0,
      'Data::UUID::Base64URLSafe' => 0,
      'Scalar::Util::Numeric' => 0,
      'Image::Math::Constrain' => 0,
      'File::MMagic'           => 0,
      'DBD::SQLite' => 0,
      'DBD::mysql' => 0,
      'Moose' => 0,
      'File::Spec' => 0,
      'Cwd' => 0,
  }
);

