require 'nokogiri'
require 'open-uri'
require 'csv'

namespace :scrape do
  desc "scrape homecare.nyhealth.gov/"
  task :homecare => :environment do

    CSV.open("scrapings.csv", 'w') do |csv|
      csv << ["Company", "City", "State", "County", "Number", "Ownership", "Operator Name", "Operator City", "Operator State", 
                   "Services 1", "Services 2", "Services 3", "Services 4", "Services 5", "Services 6", "Services 7", "Services 8"]

      counties_page = Nokogiri::HTML(open("http://homecare.nyhealth.gov/index.php"))
      counties = counties_page.css("#select_county option").collect { |opt| opt['value'].gsub(" ", "%20") }

      #counties = ["Albany"] #,"Allegany","Bronx"]
      counties.each do |county|
        puts county
        county_doc = Nokogiri::HTML(open("http://homecare.nyhealth.gov/search_results.php?form=COUNTY&rt=#{county}&show=LHCSA#LHCSA"))
        
        county_doc.css("#nhpnavigation + * a").each do |listing|
          base_url = "http://homecare.nyhealth.gov/"
          doc_url = listing['href']
          doc = Nokogiri::HTML(open(base_url+doc_url))

          par1 = doc.css('#browse-view-container p strong').inner_html
          lines = par1.split(/<br>/)
          company = lines[0]
          city, state, number, operator_city, operator_state = nil, nil, nil, nil, nil
          lines.each do |line|
            if line.match(/\d{5}$/) then 
              city_and_state = line[0..-6].split(", ")
              city = city_and_state[0]
              state = city_and_state[1]
            end
            if line.match(/^Telephone:/) then 
              number = line.gsub("Telephone:", "")
            end
          end

          ownership = nil
          par2 = doc.css('#browse-view-container p')[1].inner_html
          lines = par2.split(/<br>/)
          lines.each do |line|
            if line.match(/^Ownership:/) then 
              ownership = line.gsub("Ownership:", "")
            end
          end

          par3 = doc.css('#browse-view-container p')[2].inner_html
          lines = par3.split(/<br>/)
          operator_name = lines[0]
          lines.each do |line|
            if line.match(/\d{5}$/) then 
              operator_city_and_state = line[0..-6].split(", ")
              operator_city = operator_city_and_state[0]
              operator_state = operator_city_and_state[1]
            end
          end

          services = doc.css('#browse-view-container ul')[0].css('li').collect { |li| li.inner_text }

          csv << [company, city, state, county, number, ownership, 
                  operator_name, operator_city, operator_state] + services
        end
      end
    end

  end
end