# -*- coding: utf-8 -*-
module Localfoods

  def get_farmer(url)
    puts url

    
    @a.get(url) do |page|
      # Scrape the right column to get farmer's profile
      farmer = {
        name:        page.title,
        #        description: page.at('#sobi2Details_field_description p').inner_text,
        stree:       page.at('#sobi2Details_field_street').inner_text,
        postcode:    page.at('#sobi2Details_field_postcode').inner_text,
        city:        page.at('#sobi2Details_field_city').inner_text,
        county:      page.at('#sobi2Details_field_county').inner_text,
        website:     page.at('#sobi2Details_field_website').inner_text,
        contact:     page.at('#sobi2Details_field_contact_person').inner_text,
        #        monthes:     page.at('#sobi2Listing_field_openmonths').inner_text,
        days:        '',
        hours:       page.at('#sobi2Details_field_openinghours').inner_text,
        #        facilities:  page.at('#sobi2Listing_field_facilities').inner_text,
        phone:       page.at('#sobi2Details_field_phone').inner_text,
        #        produces:    page.at('#sobi2Details_field_farmshop_own_products').inner_text,
        awards:      page.at('#sobi2Details_field_awardwinner_text').inner_text
      }
      return farmer;
    end
  end

end
