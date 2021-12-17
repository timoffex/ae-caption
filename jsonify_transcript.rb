#!/usr/bin/ruby


def fail(message)
  STDERR.puts message
  exit 1
end


def parse_time_seconds(time)
  unless /^\d+:\d\d$/.match(time)
    raise ArgumentError.new('Invalid timestamp: ' + time) 
  end

  minutes, seconds = time.split(':')
  minutes.to_i * 60 + seconds.to_i
end


lines = File.read(ARGV[0]).split("\n")
clip_start_time = 0

if ARGV.length > 1
  clip_start_time = parse_time_seconds(ARGV[1])
end

if ARGV.length > 2
  fail("Got #{ARGV.length} arguments, but only up to 2 allowed.\n" +
       "Usage: jsonify_transcript.rb <transcript_file> [clip_start_time]")
end

unless lines.length % 2 == 0
  fail('Transcript must have an even number of lines' +
       ' alternating between timestamps and captions')
end


puts "var transcript = [\n"

(0..lines.length / 2 - 1).each do |idx|
  timestamp = lines[idx * 2]

  begin
    seconds = parse_time_seconds(timestamp) - clip_start_time
  rescue StandardError => e
    fail("On line #{idx * 2} (starting from 0) in transcript.txt," +
         " error: #{e.message}")
  end

  if seconds >= 0
    caption = lines[idx * 2 + 1]
    puts "    [#{seconds}, \"#{caption}\"],\n"
  end
end

puts "];\n"
