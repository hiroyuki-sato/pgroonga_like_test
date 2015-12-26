#!/usr/bin/env ruby 
require 'csv'
require 'securerandom'
require 'uri'


idx = 0
('a'..'z').each do |u_char|
  ('aaa'..'zzz').each do |p_str|
    1.upto(50).each do |n|
      idx += 1
      puts [idx,"http://a#{u_char}.yahoo.co.jp/"+p_str+'/'+SecureRandom.hex(15)].to_csv
    end
  end

end
