# -*- coding: utf-8 -*-
module Chigasaki

  # Scrape the farmers top page to get the list of URL
  def get_url()
    top_url      = 'http://oishi-chigasaki.com/eat/farm-stand/',
    top_selector = 'li.heightLine-farmers a'
    url = []

    @a.get(top_url) do |page|
      contents = page.search(top_selector).each do |link|
        url.push(link['href'])
      end
    end

    # Save the list of individual farmer's URL to a yaml file
    db = YAML::Store.new(@config[:file_url])
    db.transaction do
      db[:url] = url
    end
  end

  def get_farmer(url)

    @a.get(url) do |page|
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
              farmer[:latitude]  = $1
              farmer[:longitude] = $2
            elsif /住所：(.*)\'\, offset\)/u =~ l
              info = $1.split("<br />")
              farmer[:address] = info[0]
              farmer[:days]    = info[1].delete('営業日：')
              farmer[:hours]   = info[2].delete('営業時間：')
              farmer[:phone]   = info[3].delete('連絡先：')
            end
          end # each
        end # CDATA
      end # script.each
      return farmer
    end # @a.get

  end # get_detail()

end
