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
  $options          = [],
  $dir_ensure       = false,
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
  validate_bool($dir_ensure)

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

  anchor { "mountt::mount::${name}::begin": }
  anchor { "mountt::mount::${name}::end": }

  if ($dir_ensure == true) {
    exec { "mkdir_${name}":
      command => "/bin/mkdir -p ${name}",
      unless  => "/bin/ls $(dirname ${name}) 2> /dev/null | /bin/grep -q ^$(basename ${name})\$",
      require => Anchor["mountt::mount::${name}::begin"],
    }
  }

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
      before   => Anchor["mountt::mount::${name}::end"]
    }
  }

  if ($mount == true) {
  # Puppet mount provider is not aware of LABEL/UUID
  # For now i feel it's not safe to use it so this is a nasty workaround
    if ($_mount_ensure == 'present') {
      $_options = join($options, ',')
      if ($_options != '') {
        $_mount_options = "-o ${_options}"
      } else {
        $_mount_options = undef
      }
      exec { "mountt_mount_${name}":
        command => "mount -t ${fstype} ${device} ${name} ${_mount_options}",
        path    => "/sbin:/usr/sbin:/bin:/usr/bin",
        unless  => "cat /proc/mounts | grep ${name} | awk {'print \$2'} | grep -q ^${name}\$",
        before  => Anchor["mountt::mount::${name}::end"],
      }
    } elsif ($_mount_ensure == 'absent') {
      exec { "mountt_umount_${name}":
        command => "umount ${name}",
        path    => "/sbin:/usr/sbin:/bin:/usr/bin",
        onlyif  => "cat /proc/mounts | grep ${name} | awk {'print \$2'} | grep -q ^${name}\$",
      }
    }
  }
}