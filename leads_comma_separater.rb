require 'rubygems'
require 'csv'
require 'cgi'
require 'pry'
require 'active_support'
require 'active_support/core_ext' # some rails methods.. like .blank?

csv = CSV.read('csv_file_processed.csv', :encoding => 'windows-1251:utf-8')
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

  if row[3].blank? then next end # if email is blank
  

  # REALLY WEIRD LOGIC HERE, BUT ONLY WAY TO GET IT TO WORK
  # BASICALLY WE WANT TO SPLIT EMAIL BY ;
  # AND CREATE A SEPARATE LINE ITEM JUST FOR THAT EMAIL
  # I COULDN'T GET IT TO LET GO OF REFERENCES SO IT WAS LITERALLY COPYING
  # FIRST EMAIL INTO ALL NEW ROWS (A NEW ROW FOR EACH UNIQUE EMAIL PER DOMAIN)
  # SPENT A LONG TIME STUCK HERE, DONT BOTHER
  row_clone = row.dup
  row_clone[3].split(';').each do |email|
    row2 = row_clone.dup
    row2[3] = email
    output = output.push(row2)
    puts output.last[3]
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






end

binding.pry
CSV.open("csv_filtered/output_results.csv", 'w') do |csv_object|
  output.each do |row_array|
    csv_object << row_array
  end
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