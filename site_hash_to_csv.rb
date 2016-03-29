require 'csv'
require 'pry'
require 'nokogiri'
require 'open-uri'

###### site_hash to CSV 




processed_csv_file = 'csv_file_processed_shopify.csv'
CSV.open(processed_csv_file, "wb") do |csv|


  hash_file = "site_hash"
  site_hash = Marshal.load(File.read(hash_file))



  csv << [
    'site',
    'twitters0',
    'twitters1',
    'emails0',
    'emails1',
    'country',
    'pages_crawled',
    'redirect_pages'
  ]


  indx = 0
  site_hash.each do |key, value|


    
    csv << [
      key,
      value['twitters0'],
      value['twitters1'],
      value['emails0'],
      value['emails1'],
      value['country'],
      value['pages_crawled'],
      value['redirect_pages']
    ]


    puts indx
    indx+=1


  end







end # csv


# ####### after csv creation processing


# processed_csv_file = 'csv_file_processed.csv'
# indx = 0
# CSV.open(processed_csv_file, "wb") do |csv|

#   CSV.foreach("output.csv") do |row|
#     # use row here...

#     if indx > 20000 then next end

#     begin
#       # binding.pry
#       key = row[0]
#       doc = Nokogiri::HTML(open(key+'/cart'))
#       found = doc.inner_html.include?('cdn.shopify.com')
#     rescue
#       found = 'error'
#     end


#     row << found

#     csv << row


#     if indx%20 == 0 
#       puts indx/12000.0 
#       puts Time.now
#     end 

#     indx += 1



#   end


# end


