#
# Cookbook Name:: omnibus-custom
# Recipe:: default
#
# Copyright (C) 2014
#
#
#

case node.platform_family
when "rhel"
  node.default['yum']['epel']['enabled'] = true
  include_recipe "yum-epel"
end

package "fakeroot"
package "sudo"

include_recipe "omnibus"

cookbook_file "/usr/local/bin/omnibus-autobuild" do
  source "omnibus-autobuild.sh"
  mode "0755"
end

cookbook_file "/usr/local/share/omnibus-autobuild.rb" do
  source "omnibus-autobuild.rb"
  mode "0755"
end

sudo "omnibus" do
  user "omnibus"
  nopasswd true
  defaults ['!requiretty']
end

case node.platform_family
when "rhel"
  resources(:execute => "selinux-permissive").action(:nothing)
end

ruby_gem "omnibus" do
  ruby node['omnibus']['ruby_version']
  version node['omnibus-custom']['omnibus']['version']
end

ruby_gem "mixlib-shellout" do
  ruby node['omnibus']['ruby_version']
end
