#!/usr/bin/env ruby
# coding: utf-8

require 'yaml'
require 'ap'

config = YAML.load_file("config.yaml")
config_file = File.new( config['system']['output'], 'w')
host_groups = Hash.new

config['contacts'].each do |contact|
    template = File.read('objects/contacts.cfg')
    template.scan(/%%([A-Z]+)%%/).each do |match|
        template.gsub!("%%"+match[0]+"%%", contact[ match[0].downcase ])
    end
    config_file.puts template+"\n"
end

config['groups'].each do |group|
    template = File.read('objects/contactgroups.cfg')
    group['members'] = group['members'].join(",")
    template.scan(/%%([A-Z]+)%%/).each do |match|
        template.gsub!("%%"+match[0]+"%%", group[ match[0].downcase ])
    end
    config_file.puts template+"\n"
end

config['hosts'].each do |host|
    template = File.read('objects/hosts.cfg')
    template.scan(/%%([A-Z]+)%%/).each do |match|
        template.gsub!("%%"+match[0]+"%%", host[ match[0].downcase ])
    end
    config_file.puts template+"\n"

    host['services'].each do |service|

        if service =~ /^check_([a-z]+)/
            description = $1.upcase
            command = service
        else
            description = service.upcase
            command = "check_"+service
        end

        template = File.read('objects/services.cfg')
        template.gsub!("%%HOSTNAME%%", host['host'])
        template.gsub!("%%DESCRIPTION%%", description)
        template.gsub!("%%CONTACTGROUP%%", host['group'])
        template.gsub!("%%COMMAND%%", command)
        config_file.puts template+"\n"
    end
end

config_file.close

exec(config['system']['postcmd']) if config['system']['postcmd']
