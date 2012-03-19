# A couple of scripts to help a bit out with Nagios

## Generate Nagios configuration files

The file `build_config.rb` will read a configuration file in yaml and create Nagios configuration files.

1) `cp config-example.yaml config.yaml`

2) Edit `config.yaml`

3) `./build_config.rb`

### Please note

The tool doesn't generate all configuration files, only these definitions is created:

 - contacts
 - contactgroups
 - hosts
 - services

## Display nagios status in cli

I don't really like watching my nagios status in an webinterface (that requires a nice blend of php and cgi!) so `status.rb` will read the nagios status.dat file and display host and service status information in cli.

1) `cp status_config-sample.yaml status_config.yaml`

2) Edit `status_config.yaml` (note: server is optional)

3) `./status.rb`

- Enjoy