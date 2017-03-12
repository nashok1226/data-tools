#!/usr/bin/env ruby
#
#  REQUIREMENTS:
#
#    $ sudo gem install json
#
#  SPECIAL VARIABLES:
#
#    $_
#    $nr
#
#  DESCRIPTION:
#
#    Read from standard input JSON objects, one per line.
#    Parse each JSON object and put the data in the special
#    variable $_.  Execute the command line specified
#    script.
#
#    If the -j or -t flags are specifed, write the
#    value in the $_ to standard out as JSON or in tab delimited
#    format.

require 'getoptlong'

def usage
  $stderr.puts 'USAGE: json-ruby  [-j|-t] [-i] (-f SCRIPT_FILE | SCRIPT) [JSON_FILE] ...'
  exit 1
end

opts = GetoptLong.new(
  ['--file', '-f',
   GetoptLong::OPTIONAL_ARGUMENT],
  ['--json', '-j',
   GetoptLong::NO_ARGUMENT],
  ['--ignore-invalid-json', '-i',
   GetoptLong::NO_ARGUMENT],
  ['--tsv', '-t',
   GetoptLong::NO_ARGUMENT],
  ['--help', '-h',
   GetoptLong::NO_ARGUMENT]
)

script = nil
output_format = nil
ignore = false

opts.each do |opt, arg|
  case opt
  when '--file'
    script = File.open(arg).read
  when '--json'
    output_format = :json
  when '--ignore'
    ignore = true
  when '--tsv'
    output_format = :tsv
  when '--help'
    usage
  end
end

unless script
  if !ARGV.empty?
    script = ARGV.shift
  else
    $stderr.puts 'ERROR: no SCRIPT or SCRIPT_FILE specified'
    usage
  end
end

cmd = ['ruby', '-n']
cmd << '-e'
cmd << 'BEGIN {require "rubygems"; require "json"; $nr = 0}'
cmd << '-e'
cmd << if ignore
         'begin; $_ = JSON.parse($_); rescue; $stderr.write("ERROR: invalid json: #{$_}"); $_ = nil; end; $nr += 1'
       else
         '$_ = JSON.parse($_); $nr += 1'
       end
cmd << '-e'
cmd << script

case output_format
when :json
  cmd << '-e'
  cmd << 'puts $_.to_json'
when :tsv
  cmd << '-e'
  cmd << 'puts $_.join("\t")'
end

cmd.concat(ARGV)

exec(*cmd)
