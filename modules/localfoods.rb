# -*- coding: utf-8 -*-
module Localfoods

  def get_farmer(url)
    img    = {
      'http://www.localfoods.org.uk/images/icons/ac.png' => :accomodation,
      'http://www.localfoods.org.uk/images/icons/fa.png' => :attraction,
      'http://www.localfoods.org.uk/images/icons/bu.png' => :butchery,
      'http://www.localfoods.org.uk/images/icons/ca.png' => :cafe,
      'http://www.localfoods.org.uk/images/icons/de.png' => :deli,
      'http://www.localfoods.org.uk/images/award_winner_icon.png' => :farma,
      'http://www.localfoods.org.uk/images/icons/fm.png' => :market,
      'http://www.localfoods.org.uk/images/icons/fc.png' => :fish,
      'http://www.localfoods.org.uk/images/icons/gologo.png' => :go,
      'http://www.localfoods.org.uk/images/icons/goallogo.png' => :goal,
      'http://www.localfoods.org.uk/images/icons/pa.png' => :parking,
      'http://www.localfoods.org.uk/images/icons/fm.png' => :pick,
      'http://www.localfoods.org.uk/images/icons/fs.png' => :store,
      'http://www.localfoods.org.uk/images/icons/t.png'  => :toilets
    }
    fields = {
      name:       'body title',
      note:       '#sobi2Details_field_description',
      street:     '#sobi2Details_field_street',
      postcode:   '#sobi2Details_field_postcode',
      city:       '#sobi2Details_field_city',
      county:     '#sobi2Details_field_county',
      url:        '#sobi2Details_field_website a',
      contact:    '#sobi2Details_field_contact_person',
      season:     '.sobi2Listing_field_openmonths',
      days:       '#sobi2Details_field_openinghours',
      facilities: '.sobi2Listing_field_facilities',
      phone:      '#sobi2Details_field_phone',
      products:   '.sobi2Listing_field_farmshop_products',
      awards:     '#sobi2Details_field_awardwinner_text'
    }
    puts "Scraping... " + url
    
    @a.get(url) do |page|
      
      # Scrape the right column to get farmer's profile
      farmer = {}
      fields.each do |key, val|
        if page.at(val)
          case key
          when :url
            farmer[key] = page.at(val)['href']
          when :season,:facilities,:products
            list = []
            page.search(val + " li").each do |li|
              list.push(li.inner_text)
            end
            farmer[key] = list.join(',')
          else
            
            farmer[key] = page.at(val).inner_text.gsub(/Phone:|Contact Person:|Opening Hours:|Description:|\r\n|\r|\n|\n\r/,'').gsub(/^[　\s]*(.*?)[　\s]*$/, '\1')
          end
        end
      end
        
      page.search('img').each do |data|
        if img.key?(data['src'])
          farmer[img[data['src']]] = 1
        end
      end

      # Scrape the CDATA section of Javascript to get geolocation, address, etc in a googlemap
      page.search('script').each do |data|
        lines = data.text().rstrip.split(/\r?\n/).map {|line| line.chomp }
        if /\/\/\<\!\[CDATA\[/ =~ lines[1]
          lines.each do |l|
            if /([\d-]*\.[\d-]*), ([\d-]*\.[\d-]*)/ =~ l
              farmer[:latitude]  = $1
              farmer[:longitude] = $2
            end
          end # each
        end # CDATA
      end # script.each
      
      return farmer;
    end
  end

  # Output farmers data to a CSV file
  def output_csv()
    db   = YAML.load_file(@config[:file_farmers])
    csv = CSV.open(@config[:file_csv],'w') do |writer|
      db[:farmers].each do |farmer|
        line = []
        @fields.each do |field|
          if farmer[field]
            line.push(farmer[field])
          else
            line.push("")
          end
        end
        writer << line
      end
    end
  end # output_csv
end
