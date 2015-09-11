postgresql:
  pkg:
    - installed
  service:
    - running

postgresql-server-dev-9.3:
  pkg:
    - installed

libpq-dev:
  pkg:
    - installed

python-virtualenv:
  pkg:
    - installed

language-pack-nl:
  pkg:
    - installed

# Psycopg2 requires compilation, so it is easier to use the standard Ubuntu
# package
python-psycopg2:
  pkg:
    - installed

python-package:
  pip.installed:
    - editable: /vagrant/
    - require:
      - pkg: python-psycopg2

# python_dateutil from pypi currently has permission issues with some files
# after installation, so use the standard Ubuntu package
python-dateutil:
  pkg:
    - installed

vagrant:
  user.present:
    - shell: /bin/zsh

  postgres_user.present:
    - login: True
    - superuser: True
    - require:
      - service: postgresql

install-pgtap:
  cmd.wait:
    - name: '/vagrant/provision/salt/roots/salt/resources/install-pgtap'
    - watch:
      - postgres_user: vagrant
    - env:
      - PGDATABASE: minerva
    - user: vagrant
    - require:
      - pkg: git

create-database:
  cmd.wait:
    - name: '/vagrant/provision/salt/roots/salt/resources/create-database'
    - user: vagrant
    - watch:
      - cmd: install-pgtap

git:
  pkg:
    - installed

/etc/minerva/instances/default.conf:
  file.managed:
    - source: salt://resources/minerva_instance.conf
    - makedirs: True

/etc/postgresql/9.3/main/postgresql.conf:
  file.append:
    - text: 'minerva.trigger_mark_modified = on'
