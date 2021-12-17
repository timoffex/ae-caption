#!/usr/bin/ruby

if ARGV.length != 2
  STDERR.puts 'Usage: add_timestamps.rb <file> <interval in seconds>'
  STDERR.puts 'Example: add_timestamps.rb transcript.txt 5'
  exit 1
end

filename = ARGV[0]
interval = ARGV[1].to_i

lines = File.read(filename).split("\n")

(0..lines.length - 1).each do |idx|
  start_time_seconds = idx * interval

  timestamp_seconds = start_time_seconds % 60
  if timestamp_seconds < 10
    timestamp_seconds = "0#{timestamp_seconds}"
  end
  timestamp_minutes = start_time_seconds.div(60)
  timestamp = "#{timestamp_minutes}:#{timestamp_seconds}"
  line = lines[idx]

  puts timestamp
  puts line
end

