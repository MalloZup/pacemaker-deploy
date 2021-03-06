{% if not grains.get('sbd_disk_device') %}
{% set sbd_disk_device = salt['cmd.run']('lsscsi | grep "LIO-ORG" | awk "{ if (NR=='~grains['sbd_disk_index']~') print \$NF }"', python_shell=true) %}
{% else %}
{% set sbd_disk_device = grains['sbd_disk_device'] %}
{% endif %}

cluster:
  name: test_cluster
  init: {{ grains['name_prefix'] }}01
  {% if grains['provider'] == 'libvirt' %}
  interface: eth1
  {% else %}
  interface: eth0
  unicast: True
  {% endif %}
  join_timeout: 180
  watchdog:
    module: softdog
    device: /dev/watchdog
  sbd:
    device: {{ sbd_disk_device }}
  ntp: pool.ntp.org
  {% if grains['provider'] == 'libvirt' %}
  sshkeys:
    overwrite: true
    password: linux
  {% endif %}
  resource_agents:
    - SAPHanaSR
  {% if grains['provider'] == 'azure' %}
  corosync:
    totem:
      token: 30000
      token_retransmits_before_loss_const: 10
      join: 60
      consensus: 36000
      max_messages: 20
  {% endif %}
  {% if grains.get('monitor_enabled', False) %}
  ha_exporter: true
  {% else %}
  ha_exporter: false
  {% endif %}
