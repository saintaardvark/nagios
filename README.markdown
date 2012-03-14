# Simple tool to generate Nagios configuration files

Create a simple configuration file in yaml and the script will create Nagios configuration files.

1) cp config-example.yaml to config.yaml

2) Edit config.yaml

3) ./build_config.rb

## Please note

The tool doesn't generate all configuration files, only these definitions is created:

 - contacts
 - contactgroups
 - hosts
 - services
