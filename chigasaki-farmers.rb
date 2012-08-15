# -*- coding: utf-8 -*-
# Author::    Jun Kaneko
# Copyright:: Copyright (c) 2012 Jun Kaneko
# License::   Distributes under the same terms as Ruby
# Date::      2012 August 14
# About::     Scrape farmers data from  http://oishi-chigasaki.com/
# Require::   Ruby 1.9+ and required rubygems
# = How to use
# Use command line to scrape and output CSV in /data directory
# % ruby chigasaki-farmers.rb [url,farmers,csv]
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

class ChigasakiFarms
  
  def initialize()
    # Create Mechanize agent
    @a = Mechanize.new { |agent|
      agent.user_agent_alias = 'Mac Safari'
    }
    dir_data = File.dirname($0) + '/data'
    @config = {
      file_url:     "#{dir_data}/url.yaml",
      file_farmers: "#{dir_data}/farmers.yaml",
      file_csv:     "#{dir_data}/farmers.csv"
    }
  end

  # Scrape the farmers top page to get the list of URL
  def getUrl()

    url = []
    @a.get('http://oishi-chigasaki.com/eat/farm-stand/') do |page|
      contents = page.search('li.heightLine-farmers a').each do |link|
        url.push(link['href'])
      end
    end

    # Save the list of individual farmer's URL to a yaml file
    db = YAML::Store.new(@config[:file_url])
    db.transaction do
      db['url'] = url
    end
  end

  # Scrap individual farmer's pages
  def getFarmers()
    farmers = []

    # Read a list of URL from the yaml
    db = YAML.load_file(@config[:file_url])
    
    db['url'].each do |url|
      @a.get(url) do |page|
      # @a.get(db['url'][0]) do |page| # For development not to scrape all the farmers

        # Scrape the right column to get farmer's profile
        profile = page.search('#noka_db_right dd')
        farmer = {
          name:      profile[0].inner_html,
          produces:  profile[1].inner_html,
          special:   profile[2].inner_html,
          available: profile[4].inner_html
        }

        # Scrape the CDATA section of Javascript to get geolocation, address, etc in a googlemap
        page.search('script').each do |data|
          lines = data.text().rstrip.split(/\r?\n/).map {|line| line.chomp }
          if lines[1] == '//<![CDATA['
            lines.each do |l|
              if /(\d*\.\d*), (\d*\.\d*)/ =~ l
                farmer['latitude']  = $1
                farmer['longitude'] = $2
                
              elsif /住所：(.*)\'\, offset\)/u =~ l
                info = $1.split("<br />")
                farmer['address'] = info[0]
                farmer['days']    = info[1]
                farmer['hours']   = info[2]
                farmer['phone']   = info[3]
              end
            end
          end

        end
        farmers.push(farmer)
      end
    end

    # Save farmer's data to a yaml
    db = YAML::Store.new(@config[:file_farmers])
    db.transaction do
      db['farmers'] = farmers
    end
  end
  
  # Output farmers data to a CSV file
  def outputCsv()
    db  = YAML.load_file(@config[:file_farmers])
    csv = CSV.open(@config[:file_csv],'w') do |writer|
      db['farmers'].each do |farmer|
        
        writer << [farmer['name'],farmer['phone'].delete('連絡先：'),farmer['latitude'],farmer['longitude'],farmer['address'],farmer['hours'].delete('営業時間：'),farmer['days'].delete('営業日：'),farmer['available'],farmer['produces'],farmer['special']]
      end
    end

  end
end

# Main program, initialize the class and call methods by ARGV[0]
farmers = ChigasakiFarms.new()

if ARGV[0] == 'url'
  farmers.getUrl()
elsif ARGV[0] == 'farmers'
  farmers.getFarmers()
elsif ARGV[0] == 'csv'
  farmers.outputCsv()
else
  puts 'Please specify the action either of url,farmers,csv at ARGV[0]'
end  



