#!/usr/bin/env ruby

require 'optparse'
require 'fileutils'

options = {}
OptionParser.new do |opts|
  opts.on("-p PROJECT", "The project to build") do |project|
    options[:project] = project
  end
  opts.on("-P [PUBLISH_GLOB]", "A glob pattern to publish matching artifacts") do |pattern|
    options[:publish_glob] = pattern
  end
  opts.on("-B [S3_BUCKET]", "The S3 bucket to publish artifacts to") do |s3_bucket|
    options[:s3_bucket] = s3_bucket
  end
  opts.on("-o [OUTPUT_DIR]", "Copy artifacts (from the pkg sub-directory) to OUTPUT_DIR") do |out_dir|
    options[:output_dir] = out_dir
  end
  opts.on("-r [REPOSITORY_URL]", "Checkout an omnibus git repository and use it as a build source") do |repo_url|
    options[:repo_url] = repo_url
  end
  opts.on("-R [REPOSITORY_PATH]", "Use REPOSITORY_PATH as the build source path") do |repo_path|
    options[:repo_path] = repo_path
  end
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!(ARGV)

def errexit(msg)
  warn msg
  exit 1
end

errexit "You must provide either -r or -R" unless options[:repo_path] or options[:repo_url]
errexit "You must provide either -o or -P" unless options[:output_dir] or options[:publish_glob]
errexit "-r and -R cannot be specified together" if options[:repo_url] and options[:repo_path]
errexit "You must provide -p" unless options[:project]

source_path = "/home/omnibus/source"
user = "omnibus"
group = "omnibus"

def sudo(command)
  system("sudo #{command}")
end

sudo "mkdir -p /opt/#{options[:project]}"
sudo "chown #{user}:#{group} /opt/#{options[:project]}"

if options[:repo_path]
  FileUtils.cp_r(options[:repo_path].sub(/\/$/, "") + "/.", source_path)
end

if options[:repo_url]
  system "git clone #{options[:repo_url]} #{source_path}"
end

FileUtils.chown user, group, source_path

Dir.chdir source_path
system "bundle install --binstubs --without development"
system "bin/omnibus build #{options[:project]}"

if options[:output_dir]
  raise RuntimeError, "output_dir is not a valid directory!" unless File.directory? options[:output_dir]
  sudo "cp #{File.join(source_path, "pkg", "/*")} #{options[:output_dir]}"
end

if options[:publish_glob]
  system "bin/omnibus publish s3 '#{options[:s3_bucket]} '#{options[:publish_glob]}'"
end
