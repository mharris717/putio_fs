require 'rubygems'
require 'rfusefs'
require 'mharris_ext'
require 'json'

module PutioFs
  def self.tmp_dir
    res = File.expand_path(File.dirname(__FILE__))+"/../tmp"
    File.expand_path(res)
  end
end

%w(putio_api put_dir).each do |f|
  load File.expand_path(File.dirname(__FILE__)) + "/putio_fs/#{f}.rb"
end