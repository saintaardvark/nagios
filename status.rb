#!/usr/bin/env ruby
# coding: utf-8

# NAGIOS CLI STATUS
# Will read the nagios status.dat file and print reasonable pretty output

require 'yaml'

# A bit of helpers
def pretty_state(state)
    states = [' UP ', 'WARN', 'CRIT', 'DISA', 'UNKN']
    colors = ['[32m', '[34m', '[31m', '[37m', '[37m']
    "\033" + colors[ state.to_i ] + states[ state.to_i ] + "\033[0m"
end

def print_row(row)
    checked = row['has_been_checked'] == "0" ? false : true;
    row['current_state'] = 4 if not checked
    print format("%20.20s", row['host_name']) + "  "
    print format("%-6s", row['service_description']) + "  "
    print pretty_state(row['current_state']) + "    "
    print format("%-25s", checked ? Time.at(row['last_check'].to_i).to_s : "NEVER" ) + "  "
    print row['plugin_output'] + "\n"
end

# Load configuration
config = YAML.load_file("status_config.yaml")

if config['server']
    `scp -q #{config['server']}:#{config['dat_file']} status.tmp`
    config['dat_file'] = './status.tmp'
end

# Parse nagios data file
data = Hash.new
capture_name = nil;
capture_object = Hash.new
datfile = File.new( config['dat_file'], 'r' )
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

host_states = [0, 0, 0, 0, 0]
service_states = [0, 0, 0, 0, 0]

if not data['hoststatus'].nil?
    data['hoststatus'].each do |host|
        host['service_description'] = "PING"
        host_states[ host['current_state'].to_i ] += 1
        print_row(host) if config['showall'] or host['current_state'] != '0'
        if not data['servicestatus'].nil?
            data['servicestatus'].each do |service|
                if service['host_name'] == host['host_name']
                    service_states[ service['current_state'].to_i ] += 1
                    service['host_name'] = "" if config['showall']
                    print_row(service) if config['showall'] or service['current_state'] != '0'
                end
            end
        end
    end
end

if config['status']
    puts "States summary:"
    host_states.each_with_index do |state, index|
        puts "Hosts     " + pretty_state(index) + "  " + state.to_s if state > 0
    end
    service_states.each_with_index do |state, index|
        puts "Services  " + pretty_state(index) + "  " + state.to_s if state > 0
    end
end