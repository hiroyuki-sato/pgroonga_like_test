#!/usr/bin/env ruby 
require 'csv'
require 'securerandom'
require 'uri'

urls = %w[ 
  http://aa.yahoo.co.jp/
  http://ab.yahoo.co.jp/
  http://ac.yahoo.co.jp/
  http://ad.yahoo.co.jp/
  http://ae.yahoo.co.jp/
]

idx = 1
urls.each do |url|
  %w[ aa bb cc dd ee ].each do |p|
    1.upto(1000).each do |n|
#     print [idx,URI.join(urls,p,SecureRandom.hex(15))].to_csv
     puts [idx,File.join(url,p,SecureRandom.hex(15))].to_csv
     idx += 1
    end
  end
end
