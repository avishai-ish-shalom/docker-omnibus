#!/usr/bin/env ruby

require 'optparse'
require 'fileutils'
require 'mixlib/shellout'

options = {}
OptionParser.new do |opts|
  opts.on("-b [BUILD_COMMAND]", "A command to run instead of `omnibus build`") do |build_command|
    options[:build_command] = build_command
  end
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
  opts.on("-R [REPOSITORY_REF]", "Checkout REPOSITORY_REF from the source repo; Should be used with -r") do |repo_path|
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

def run(command, opts={})
  err_msg = opts.delete!(:err_msg)
  cmd = Mixlib::ShellOut.new(command, opts)
  cmd.run_command
  if err_msg and cmd.err?
    errexit(err_msg + "\n" + cmd.stdout.lines.map{|l| "STDOUT: " + l} + "\n" + cmd.stderr.lines.map{|l| "STDERR: " + l})
  end
end

sudo "mkdir -p /opt/#{options[:project]}"
sudo "chown #{user}:#{group} /opt/#{options[:project]}"

if options[:repo_path]
  FileUtils.cp_r(options[:repo_path].sub(/\/$/, "") + "/.", source_path)
end

if options[:repo_url]
  run("git clone --tags #{options[:repo_url]} #{source_path}", :err_msg => "Failed to run git clone")
  run("git checkout #{options[:repo_ref]}", :cwd => source_path, :err_msg => "Failed to checkout ref #{options[:repo_ref]}") if options[:repo_ref]
end

FileUtils.chown user, group, source_path

Dir.chdir source_path
run("bundle install --binstubs --without development", :err_msg => "Failed to run bundle install")
if options[:build_command]
  run(options[:build_command], :cwd => source_path, :err_msg => "Failed to run #{options[:build_command]}")
else
  run("bin/omnibus build #{options[:project]}", :cwd => source_path, :err_msg => "Failed to run ombnibus build")
end

if options[:output_dir]
  raise RuntimeError, "output_dir is not a valid directory!" unless File.directory? options[:output_dir]
  sudo "cp #{File.join(source_path, "pkg", "/*")} #{options[:output_dir]}"
end

if options[:publish_glob]
  run("bin/omnibus publish s3 '#{options[:s3_bucket]} '#{options[:publish_glob]}'", :cwd => source_path, :err_msg => "Failed to publish artifacts to S3")
end
