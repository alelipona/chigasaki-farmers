# -*- coding: utf-8 -*-
# Author::    Jun Kaneko
# Copyright:: Copyright (c) 2012 Jun Kaneko
# License::   Distributes under the same terms as Ruby
# Date::      2012 August 14
# About::     Scrape farmers data from websites
# Require::   Ruby 1.9+ and required rubygems
# = How to use
# Use command line to scrape and output CSV in /data directory
# % ruby scrape-farmers.rb [url,farmers,csv]
# With url option, scrape the top page to get a list of farmers' URL.
# With farmers option, scrape each URL to get farmer's data.
# With csv option, output the farmer's data to a CSV file.

require 'rubygems'
require 'yaml'
require 'yaml/store'
require 'mechanize'
require 'time'
require 'kconv'
require 'date'
require 'csv'
require 'json'

class ScrapeFarmers
  
  def initialize(site)
    root = File.dirname(__FILE__)

    # Include methods to scrape each site
    case site
    when 'chigasaki'
      require "#{root}/modules/chigasaki.rb"
      extend Chigasaki
    when 'localfoods'
      require "#{root}/modules/localfoods.rb"
      extend Localfoods
    end

    # Files to save the scraped data
    @config = {
      file_url:     "#{root}/#{site}/url.yaml",
      file_farmers: "#{root}/#{site}/farmers.yaml",
      file_csv:     "#{root}/#{site}/farmers.csv",
      shonan_csv:   "#{root}/spreadsheet/shonan.csv",
      shonan_json:  "#{root}/spreadsheet/shonan.json"
    }

    # Create Mechanize agent and share among this class
    @a = Mechanize.new { |agent|
      agent.user_agent_alias = 'Mac Safari'
    }
  end

  # Scrap individual farmer's pages
  def get_farmers()
    # Read a list of URL from the yaml
    db = YAML.load_file(@config[:file_url])
    farmers = []
    
    url = db['url'][0]
    # db['url'].each do |url|
      farmers.push(get_farmer(url))
    # end

    # Save farmer's data to a yaml
    db = YAML::Store.new(@config[:file_farmers])
    db.transaction do
      db[:farmers] = farmers
    end
  end

  # Output farmers data to a CSV file
  def output_csv()
    db  = YAML.load_file(@config[:file_farmers])
    csv = CSV.open(@config[:file_csv],'w') do |writer|
      db[:farmers].each do |farmer|
        
        writer << [farmer[:name],farmer[:phone],farmer[:latitude],farmer[:longitude],farmer[:address],farmer[:hours],farmer[:days],farmer[:available],farmer[:produces],farmer[:special]]
        
      end
    end

  end

  def output_json()
    data = CSV.parse(File.open(@config[:shonan_csv],'r'))
    header = data.shift
    open(@config[:shonan_json], 'w') do |io|
      JSON.dump(data, io)
    end
  end
end

# Main program, initialize the class and call methods by ARGV[0]
farmers = ScrapeFarmers.new('localfoods')

case ARGV[0]
when 'url'
  farmers.get_url()
when 'farmers'
  farmers.get_farmers()
when 'csv'
  farmers.output_csv()
when 'json'
  farmers.output_json()  
else
  puts 'Please specify the action either of url,farmers,csv at ARGV[0]'
end 




