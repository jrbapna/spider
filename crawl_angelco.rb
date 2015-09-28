# to view db: use sqllitebrowser

# open up sauce labs virtual machine then run in JS console:

# window.page = 1;
# window.complete_html = '';


# window.grabPage = function(){
#   $.get("https://angel.co/saas?page="+window.page.toString()).success(function(data,status,xhr){
#     window.complete_html += data.html;
#     console.log('got page' + window.page.toString());
#     window.page += 1;
#     clearTimeout(window.nextpage);
#     if(window.page<500){
#       window.nextpage = setTimeout(window.grabPage, 10000);
#     }
#   });
# }

# window.grabPage(window.page);

# Then run console.log(complete_html) and copy contents to textmate where you can look for class=""





require 'rubygems'
require 'nokogiri'       
require 'csv'
require 'pg'
require 'open-uri'
require 'cgi'
require 'pry'
require 'open_uri_redirections'
require 'active_support'
require 'active_support/core_ext' # some rails methods.. like .blank?

csv = CSV.read('../../../../Desktop/leads_list_slick.csv', :encoding => 'windows-1251:utf-8')
#csv = CSV.parse(csv_text)

# @conn = PG.connect(
#   :dbname=> 'catarse_development',
#   :user=>'postgres',
#   :password=>'postgres'
# )

output = []
error_array = {}


csv.each_with_index do |row,index|
  
  if index > 50000 then next end


  if index%10 == 0
    puts "progress ----------------------------------- #{index}" 
  end

  if row[6].blank? then next end # if email is blank
  
  begin
    site = row[0]
    page = Nokogiri::HTML(open("http://www.#{site}", :allow_redirections => :all))


    row << page.title

    row << doc.css('.company_url')[0]["href"]
    row << doc.css('.blog_url')[0]["href"]
    row << doc.css('.linkedin_url')[0]["href"]
    row << doc.css('.facebook_url')[0]["href"]
    row << doc.css('.twitter_url')[0]["href"]


    output << row
  rescue => exception
    error_array[index] = exception.backtrace
    row << 'failed ' + exception.to_s
    output << row
    puts "error at: #{index}"
    puts exception
  end



  # begin
  #   site = row[12].split(';')[0]
  #   page = Nokogiri::HTML(open("http://#{site}", :allow_redirections => :all))
  #   row << page.title
  #   output << row
  # rescue => exception
  #   error_array[index] = exception.backtrace
  #   row << 'failed'
  #   output << row
  #   puts "error at: #{index}"
  #   puts exception
  # end

  if index%1000 == 0
    CSV.open("csv/output_#{index}.csv", 'w') do |csv_object|
      output.each do |row_array|
        csv_object << row_array
      end
    end
    output = []
  end

  sleep 10




end

# CSV.open('output.csv', 'w') do |csv_object|
#   output.each do |row_array|
#     csv_object << row_array
#   end
# end


# binding.pry


# CSV.open('output_safe.csv', 'w') do |csv_object|
#   output.each do |row_array|
#     csv_object << row_array
#   end
# end




error_array.each do |k,v|
  puts k
  puts v
  puts '------------------------------------------'
end


# concatenate or combine multiple csv files into one
# cat *.csv > outputfile

# keywords: crawl crawler csv




