require 'mechanize'
require 'spreadsheet'

# Initialize our Spreadsheet 
$book = Spreadsheet::Workbook.new
$xls_path = './uhn.xls'

# Initialize our scraping targets
$urls = {
  'TWRI' => 'http://www.uhnres.utoronto.ca/institutes/twri/investigators.php',
  'TGRI' => 'http://www.uhnres.utoronto.ca/institutes/tgri/investigators.php',
  'OCI' => 'http://www.uhnres.utoronto.ca/institutes/oci/investigators.php'
}

# Initialize Mechanize Agent
$agent = Mechanize.new

# Pass in URL Index Page and Fill it up with Good Stuff :)
def fill_sheet(sheet_name, url)
  page = $agent.get url
  profiles = page.links_with :href => /profile.php/

  current_row_number = 0
  sheet = $book.create_worksheet :name => sheet_name

  # Parameters
  puts "Filling up for #{sheet_name} at #{url.to_s}"

  # Header
  sheet.row(current_row_number).concat ['Name', 'Research Interests', 'E-mail (Link)', 'Link to Profile']
  current_row_number += 1
  
  # Fill it with Data
  profiles.each do |profile_link|
    profile = profile_link.click

    # Name
    name = profile.search("//div[@id='name']").inner_text.strip
    
    # Research Interests
    research_interests = profile.search("//div[@id='research_interests']").inner_text.strip
     
    # E-mail
    mail_path = '/researchers/' + profile.link_with(:href => /mailto.php/).uri.to_s

    # Set Path
    full_mail_path = URI(mail_path)
    # Set Base URL
    full_mail_path.host = $agent.page.uri.host
    # Set HTTP
    full_mail_path.scheme = $agent.page.uri.scheme

    puts "E-mail: #{full_mail_path.to_s}"
    
    # Profile Link
    profile_link = $agent.page.uri.to_s
    puts "Profile: #{$agent.page.uri.to_s}"

    sheet.row(current_row_number).concat  [name, 
      research_interests, 
      Spreadsheet::Link.new(full_mail_path.to_s, full_mail_path.to_s), 
      Spreadsheet::Link.new(profile_link, profile_link)]  
    current_row_number += 1
  end

  puts "Finished a Sheet!"

end

# Begin...
puts "Searching Profiles..."

# Fill up those sheets
$urls.each do |name, url|
  fill_sheet(name, url)
end

# Finish up writing in the book
$book.write $xls_path
