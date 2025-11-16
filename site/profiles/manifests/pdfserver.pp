class profiles::pdfserver (
) {
  $path='/opt/Stirling-PDF'
  $file_service = '/etc/systemd/system/stirling-pdf.service'

  package { [
    'openjdk-17-jdk',
    'wget',
    'git',
    'make',
    'gcc',
    'g++',
    'automake',
    'autoconf',
    'libtool',
    'pkg-config',
    'zlib1g-dev',
    'libleptonica-dev',
    'libreoffice-core', 
    'libreoffice-common',
    'libreoffice-writer',
    'libreoffice-calc',
    'libreoffice-impress',
    'python3.11-venv'
  ]:
    ensure => installed,
  }
  python::pyvenv { 'Create Venv Python':
    ensure => present,
    owner  => 'pdf',
    venv_dir   => "${path}/venv",
    group  => 'pdf',
  }

  python::pip { [
  'uno',
  'opencv-python-headless',
  'unoserver',
  'pngquant',
  'WeasyPrint',
  ]:
    ensure  => present, 
    virtualenv => "${path}/venv",
    owner      => 'pdf', 
  }

  file { "${path}":
    ensure  => directory,
    owner   => 'pdf',
    group   => 'pdf',
    mode    => '0755',
  }

  user {'pdf':
    ensure     => present,
    managehome => true,
  }
  file { '/home/pdf/.git':
    ensure => directory,
    owner  => 'pdf',
    group  => 'pdf',
    mode   => '0700',
  }
  vcsrepo { '/home/pdf/.git/jbig2enc':
    ensure   => present,
    provider => git,
    source   => 'https://github.com/agl/jbig2enc.git',
    user     => 'pdf',
    require  => File['/home/pdf/.git'],
  }

  file { 'Get jar':
    ensure  => file,
    path    => "${path}/Stirling-PDF.jar",
    owner   => 'pdf',
    group   => 'pdf',
    mode    => '0755',
    source  => 'puppet:///modules/files/Stirling-PDF.jar',
    require => File[$path],
  } 


  systemd::unit_file { 'stirling-pdf.service':
    content => "[Unit]
  Description=Stirling PDF server
  After=network.target

  [Service]
  User=pdf
  Group=pdf
  WorkingDirectory=/opt/Stirling-PDF
  ExecStart=/usr/bin/java -jar /opt/Stirling-PDF/Stirling-PDF.jar
  Restart=on-failure
  SuccessExitStatus=143

  [Install]
  WantedBy=multi-user.target",
    notify  => Service['stirling-pdf'],
  }

  service { 'stirling-pdf':
    ensure => running,
    enable => true,
  }
}
