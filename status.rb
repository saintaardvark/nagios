#!/usr/bin/env ruby
# coding: utf-8

require 'yaml'

# A bit of helpers
def pretty_state(state)
    states = ['UP', 'WARNING', 'CRITICAL', 'DISABLED']
    colors = ['[32m', '[34m', '[31m', '[37m']
    "\033" + colors[ state.to_i ] + states[ state.to_i ] + "\033[0m"
end

# Load configuration
config = YAML.load_file("status_config.yaml")

if config['dat_file_server']
    `scp -q #{config['dat_file_server']}:#{config['dat_file_path']}/#{config['dat_file_name']} status.tmp`
    config['dat_file_path'] = '.'
    config['dat_file_name'] = 'status.tmp'
end

# Parse nagios data file
data = Hash.new
capture_name = nil;
capture_object = Hash.new
datfile = File.new( config['dat_file_path'] + '/' + config['dat_file_name'], 'r')
while (line = datfile.gets)
    if line =~ /^([a-z]+) \{/
        capture_name = $1.to_s
        capture_object = Hash.new
    elsif line =~ /^\s+\}/
        data[ capture_name ] = Array.new if data[ capture_name ].nil?
        data[ capture_name ] << capture_object
        capture_name = nil
        capture_object = nil
    elsif line =~ /^\s+([a-z0-9_]+)=(.*)$/
        if not capture_name.nil? and capture_object.kind_of?(Hash)
            capture_object[ $1.to_s ] = $2.to_s
        end
    end
end
datfile.close

# Puts readable data
if not data['info'].nil?
    puts "Last update at "+ Time.at(data['info'][0]['created'].to_i).to_s + " by nagios version " + data['info'][0]['version']
end

if not data['hoststatus'].nil?
    data['hoststatus'].each do |host|
        puts host['host_name'] + "\t" + "PING\t" + pretty_state(host['current_state']) + "\t" + host['last_check'] + "\t" + host['plugin_output']
        if not data['servicestatus'].nil?
            data['servicestatus'].each do |service|
                if service['host_name'] == host['host_name']
                    puts "\t\t\t" + service['service_description'] + "\t" + pretty_state(service['current_state']) + "\t" + service['last_check'] + "\t" + service['plugin_output']
                end
            end
        end
    end
end
