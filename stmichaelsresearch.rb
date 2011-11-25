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
  file.puts "Name: "
  file.puts name.text

  # Research Interests 
  # Get exclusion of start H4 and next H4
  research_interests_top = profile_page.search('//h4[text()="Research Interests"]/following-sibling::p')
  research_interests_below = profile_page.search('//h4[text()="Research Interests"]/following-sibling::h4[1]//following-sibling::*|//h4[text()="Research Interests"]/following-sibling::h4[1]//self::*')
  research_interests = research_interests_top - research_interests_below

  file.puts "Research Interests:"
  research_interests.each do |interest|
    file.puts interest.text
  end

  # Research Activities 
  # Get exclusion of start H4 and next H4
  research_activities_top = profile_page.search('//h4[text()="Research Activities"]/following-sibling::*')
  research_activities_below = profile_page.search('//h4[text()="Research Activities"]/following-sibling::h4[1]//following-sibling::*|//h4[text()="Research Activities"]/following-sibling::h4[1]//self::*')
  research_activities = research_activities_top - research_activities_below

  file.puts "Research Activities:"
  research_activities.each do |activity|
    file.puts activity.text
  end
  
  # E-mail
  profile_email = profile_page.link_with(:href => /mailto:/)

  file.puts "E-mail:" 
  if profile_email.nil?
    file.puts "N/A"
  else
    file.puts profile_email.text
  end

  # Process Contact Information
  contact_array = contact_block.text
              .split(/phone.|fax.|e.mail./i)
              .each{|entry| entry.gsub /\s+/, '' }
              .reject{ |entry| entry.empty? }

  # If phone exists, fax exists is a rule for these profiles
  phone_dne = contact_block.text.match(/phone/i).nil?
  fax_dne = contact_block.text.match(/fax/i).nil?
  
  # Phone
  file.puts "Phone #:"
  if phone_dne
    file.puts "N/A"
  else
    file.puts contact_array[0]
  end

  # Fax - Second Entry if it Exists
  file.puts "Fax #:"
  if fax_dne
    file.puts "N/A"
  else
    file.puts contact_array[1]
  end

  file.puts "\n"

  agent.back
end

puts "Done"
