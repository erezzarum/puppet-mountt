define mountt::mount (
  $ensure           = 'present',
  $mounttab_ensure  = undef,
  $mount_ensure     = undef,
  $mounttab         = true,
  $mount            = true,
  $remounts         = true,
  $dump             = 1,
  $pass             = 2,
  $atboot           = true,
  $provider         = 'augeas',
  $device           = undef,
  $fstype           = undef,
  $options          = []
) {

  validate_absolute_path($name)
  validate_re($ensure, '^(present|absent)$')

  validate_bool($mounttab)
  validate_bool($mount)
  validate_bool($remounts)
  validate_integer($pass)
  validate_string($provider)
  validate_string($device)
  validate_string($fstype)
  validate_array($options)

  $_mounttab_ensure = $mounttab_ensure ? {
    undef   => $ensure,
    default => $mounttab_ensure,
  }
  validate_re($_mounttab_ensure, '^(present|absent)$')

  $_mount_ensure = $mount_ensure ? {
    undef   => $ensure,
    default => $mount_ensure,
  }
  validate_re($_mount_ensure, '^(present|absent)$')

  if ($mounttab == true) {
    mounttab { $name:
      ensure   => $_mounttab_ensure,
      device   => $device,
      fstype   => $fstype,
      options  => $options,
      dump     => $dump,
      pass     => $pass,
      atboot   => $atboot,
      provider => $provider,
    }
  }

  if ($mount == true) {
    mountpoint { $name:
      ensure   => $_mount_ensure,
      device   => $device,
      options  => $options,
      remounts => $remounts,
    }
  }
}