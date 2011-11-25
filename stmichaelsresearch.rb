#!/usr/bin/ruby

require 'rubygems'
require 'mechanize'

file_name = "stmichaels.txt"
file = File.new(file_name, "w+");

agent = Mechanize.new
url = 'http://www.stmichaelshospital.com/research/profilelist.php'

# Fetch that page!
page = agent.get url
profile_index = page.links_with(:href => /profile.php/)

# Excel Header
file.puts "Name:\tResearch Interests:\tResearch Activities:\tEmail:\tPhone #:\tFax #:"

# Scrape the Profile Links
profile_index.each do |link|
  puts "Scanning... " + link.href
  
  # Go to the page and grab research data + contact blocks
  profile_page = agent.click link
  contact_block = profile_page.search('//h4[text()="Contact"]/following-sibling::p[1]')
  research_interests_block = profile_page.search('//h4[text()="Research Interests"]/following-sibling::p')
  research_activities_block = profile_page.search('//h4[text()="Research Activities"]/following-sibling::p')

  # Name
  name = profile_page.search('//h4[1]')
  excel_string = name.text + "\t"
  #puts name.text
  
  # E-mail
  profile_email = profile_page.link_with(:href => /mailto:/)

  if profile_email.nil?
    #puts "N/A"
    excel_string << "N/A\t"
  else
    #puts profile_email.text
    excel_string << profile_email.text + "\t"
  end


  # Research Interests 
  # Get exclusion of start H4 and next H4
  research_interests_top = profile_page.search('//h4[text()="Research Interests"]/following-sibling::p')
  research_interests_below = profile_page.search('//h4[text()="Research Interests"]/following-sibling::h4[1]//following-sibling::*|' +
                                                  '//h4[text()="Research Interests"]/following-sibling::h4[1]//self::*')
  research_interests = research_interests_top - research_interests_below

  research_interests.each do |interest|
    #puts interest.text
    excel_string << interest.text + " "
  end
  excel_string << "\t"

  # Research Activities 
  # Get exclusion of start H4 and next H4
  research_activities_top = profile_page.search('//h4[text()="Research Activities"]/following-sibling::*')
  research_activities_below = profile_page.search('//h4[text()="Research Activities"]/following-sibling::h4[1]//following-sibling::*|' + 
                                                  '//h4[text()="Research Activities"]/following-sibling::h4[1]//self::*')
  research_activities = research_activities_top - research_activities_below

  research_activities.each do |activity|
    #puts activity.text
    excel_string << activity.text + " "
  end
  excel_string << "\t"

  # Process Contact Information
  contact_array = contact_block.text
              .split(/phone.|fax.|e.mail./i)
              .each{|entry| entry.gsub /\s+/, '' }
              .reject{ |entry| entry.empty? }

  # If phone exists, fax exists is a rule for these profiles
  phone_dne = contact_block.text.match(/phone/i).nil?
  fax_dne = contact_block.text.match(/fax/i).nil?
  
  # Phone
  if phone_dne
    #puts "N/A"
    excel_string << "N/A\t"
  else
    #puts contact_array[0]
    excel_string << contact_array[0] + "\t"
  end

  # Fax - Second Entry if it Exists
  if fax_dne
    #puts "N/A"
    excel_string << "N/A\t"
  else
    #puts contact_array[1]
    excel_string << contact_array[1] 
  end

  file.puts excel_string

end

puts "Done"
