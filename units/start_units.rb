#!/usr/bin/env ruby

require 'json'

# Wait for the unit to start on all nodes.
def wait_for_start(unit_name)
  while
    output = %x[fleetctl list-units]
    unit_status = []

    output.each_line do |line|
      cols = line.split(' ')
      unit_status.push(cols[3]) if cols[0] == unit_name
    end

    if unit_status.uniq == ['running']
      break
    else
      puts "waiting for #{unit_name} to start"
      sleep(2)
    end
  end

  puts "#{unit_name} started"
end

# Start a unit and wait for all nodes to start.
def start_unit(unit_name)
  puts "Starting #{unit_name}"

  while
    output = %x[fleetctl start #{unit_name}]

    if output.include?('Error')
      puts output
      puts "retrying start for #{unit_name}"
      sleep(2)
    else
      break
    end
  end

  wait_for_start(unit_name)
end

# Start multiple instances of a unit from a template.
def start_n_units(unit_template, unit_count)
  for unit_num in 1..unit_count
    unit_name = unit_template.gsub('@', '@' + unit_num.to_s)
    start_unit(unit_name)
  end
end

# Submit a unit file to fleet and check it has loaded.
def submit_unit(unit_name)
  puts "Submitting #{unit_name}"

  while
    %x[fleetctl submit #{File.dirname(__FILE__)}/#{unit_name}]
    output = %x[fleetctl list-unit-files]

    if output.include?(unit_name)
      break
    else
      puts "retrying submit for #{unit_name}"
      sleep(2)
    end
  end

  puts "#{unit_name} submitted"
end

# Load units metadata.
data = JSON.parse(IO.read(File.dirname(__FILE__) + '/units.json'))
units = data['units']

units.each do |unit|
  unit_name = unit['name']
  instances = unit['instances']

  submit_unit(unit_name)

  if unit['start'] == true
    if instances.nil?
      start_unit(unit_name)
    else
      start_n_units(unit_name, instances)
    end
  end
end
