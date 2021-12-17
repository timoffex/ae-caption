#!/usr/bin/ruby

def main
  transcriber = Transcriber.create_from_options!
  transcriber.read_transcript_contents!
  transcriber.construct_transcript!
  transcriber.ask_for_confirmation!
  transcriber.transcribe!
rescue StandardError => e
  puts 'Encountered an error!'
  puts e
  exit 1
end

class Transcriber
  def initialize(options, transcript_filename:)
    @should_insert_timestamps = options.key?(:interval)
    @timestamp_interval = options[:interval].to_i
    @clip_start_seconds = options[:clip_start_seconds] || 0
    @transcript_filename = transcript_filename
  end

  def read_transcript_contents!
    unless File.exist?(@transcript_filename)
      puts "File #{@transcript_filename} not found!"
      exit 1
    end

    @transcript_contents = File.read(@transcript_filename)
  end

  def construct_transcript!
    if @should_insert_timestamps
      make_transcript_with_added_timestamps!
    else
      make_transcript_with_parsed_timestamps!
    end
  end

  def make_transcript_with_added_timestamps!
    @transcript = []

    seconds = 0
    @transcript_contents.split("\n").each do |line|
      @transcript.append([seconds, line])
      seconds += @timestamp_interval
    end
  end

  def make_transcript_with_parsed_timestamps!
    @transcript = []

    lines = @transcript_contents.split("\n")

    if lines.length.odd?
      puts 'Transcript must have an even number of lines, with' \
           ' timestamps and captions on alternating lines. Did you' \
           ' mean to specify --addtimestamps? Use --help to see options.'
      exit 1
    end

    (0..lines.length / 2 - 1).each do |idx|
      timestamp = lines[idx * 2]

      begin
        seconds = parse_time_seconds(timestamp) - @clip_start_seconds
      rescue StandardError => e
        puts "On line #{idx * 2} (starting from 0) in the transcript," \
             " error: #{e.message}. See --help for options."
        exit 1
      end

      if seconds >= 0
        caption = lines[idx * 2 + 1]
        @transcript.append([seconds, caption])
      end
    end
  end

  def ask_for_confirmation!
    puts 'About to insert the following transcript:'
    @transcript.each do |entry|
      timestamp = to_time_string(entry[0])
      caption = entry[1]
      puts "#{timestamp}: #{caption}"
    end

    return if yesno('Continue?')

    puts 'Okay! Stopping now without doing anything.'
    exit 0
  end

  def transcribe!
    puts 'Generating After Effects script in file /tmp/transcribe.jsx...'
    File.open('/tmp/transcribe.jsx', 'w') do |file|
      file.write("var transcript = [\n")
      @transcript.each do |entry|
        seconds = entry[0]
        caption = entry[1].gsub('"', '\"')
        file.write("  [#{seconds}, \"#{caption}\"],\n")
      end
      file.write("];\n")
      file.write(
        <<~JSX
          var comp = app.project.activeItem;


          // Delete existing "Generated Captions" text layer
          for (var i = 1; i <= comp.numLayers; i++) {
              if (comp.layer(i).name == "Generated Captions") {
                  comp.layer(i).remove();
              }
          }

          // Create new "Generated Captions" text layer
          var captionLayer = comp.layers.addText("Generated Captions");
          captionLayer.name = "Generated Captions";

          // Start with no captions
          captionLayer.sourceText.setValueAtTime(0, "");

          // Set captions from transcript variable
          for (var i = 0; i < transcript.length; i++) {
              var time = transcript[i][0];
              var text = transcript[i][1];
              captionLayer.sourceText.setValueAtTime(time, text);
          };
        JSX
      )
    end
    puts 'Done!'

    puts 'Running script /tmp/transcribe.jsx in After Effects...'
    system <<~OSASCRIPT
      osascript -l JavaScript -e "
      ae = Application('Adobe After Effects 2022');
      ae.activate();
      ae.doscriptfile('/tmp/transcribe.jsx');
      "
    OSASCRIPT
    puts 'Done!'
  end

  def self.create_from_options!
    require 'optparse'

    options = {}
    OptionParser.new do |opts|
      opts.banner = 'Usage: transcribe.rb <transcript> [options]'

      opts.on('-a', '--addtimestamps <seconds_spacing>',
              'Inserts timestamps into the transcript') do |interval|
        options[:interval] = interval
      end

      opts.on('-t', '--start-time <mm:ss>',
              'Specifies a time offset to subtract from all timestamps' \
              ' in the transcript') do |timestamp|
        options[:clip_start_seconds] = parse_time_seconds(timestamp)
      end
    end.parse!

    if ARGV.length == 1
      transcript_filename = ARGV.pop
    else
      puts 'Transcript file not specified; defaulting to transcript.txt'
      transcript_filename = 'transcript.txt'
    end

    Transcriber.new(options, transcript_filename: transcript_filename)
  end
end

def parse_time_seconds(time_string)
  raise ArgumentError, "Invalid timestamp: #{time_string}"\
    unless /^\d+:\d\d$/.match(time_string)

  minutes, seconds = time_string.split(':')
  minutes.to_i * 60 + seconds.to_i
end

def to_time_string(seconds)
  timestamp_seconds = seconds % 60
  timestamp_seconds = "0#{timestamp_seconds}" if timestamp_seconds < 10
  timestamp_minutes = seconds.div(60)
  "#{timestamp_minutes}:#{timestamp_seconds}"
end

def yesno(prompt)
  print "#{prompt} [y/n]: "
  $stdout.flush

  loop do
    case gets.chomp.downcase
    when 'y'
      return true
    when 'n'
      return false
    else
      print 'Please enter Y or N: '
      $stdout.flush
    end
  end
end

main
