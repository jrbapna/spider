# adding these two removed that dependency conflict (two gems, unirest and another one had different dependency requirements for the same dependency)
# so remember to use bundler!!!! (gemfile)
require "rubygems" 
require "bundler/setup"

require 'uri'
require 'anemone'
require 'pry'
require_relative 'data'
require_relative 'tld_list'
require_relative 'get_domain_function'
require_relative 'sites_to_crawl'
require 'global_phone'
GlobalPhone.db_path = 'global_phone.json'
require 'unirest'

require 'active_support/all' # for time 5.minutes and stuff
require 'time'
require 'redis'
require 'redis-namespace'






UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.1 Safari/537.36'

def crawl_url(target, target_indx, site_hash, errors, storage, is_redirect)

  begin
  if !target.include? 'http'
    target = 'http://' + target
  end




  #### TIME OUT LOGIC
  dom = get_domain(target)
  started_time = REDIS.get('timestamp_'+dom.to_s)
  if started_time.nil? 
    REDIS.set('timestamp_'+dom.to_s, Time.now)
  else
    if Time.parse(started_time) < Time.now - 5.minutes 
      throw 'halting we\'re -------overtime------'
    end
  end 



  uri = URI(target)
  #site = Site.first_or_create({ :host => uri.host }, { :created_at => Time.now })
  $stderr.puts "Scanning #{uri.host}"

  # output structure columns
  # domain
  # emails
  # twitters

  Anemone.crawl(target, :depth_limit => 1, :user_agent=>UA) do |anemone|

    anemone.storage = storage
    
    anemone.on_every_page do |crawled_page|

      if crawled_page.url.to_s.include? 'https://www.azuqua.com/solutions' then binding.pry end



      domain = get_domain(target)
      if !site_hash.has_key?(domain)
        site_hash[domain] = {}
        site_hash[domain]['twitters0'] = []
        site_hash[domain]['twitters1'] = []
        site_hash[domain]['emails0'] = []
        site_hash[domain]['emails1'] = []
        site_hash[domain]['country'] = []
        site_hash[domain]['pages_crawled'] = 0
        site_hash[domain]['redirect_pages'] = 0
      end

      puts '------------------- Domain #' + target_indx.to_s + '---------------------'
      puts crawled_page.url
      puts crawled_page.code


      # remember that by default, anemone only follows links that are in your domain (no external links, so no need for that logic)
      if ( crawled_page.code == nil || crawled_page.code >= 400 )
        next
      end


      if(site_hash[domain] )
        puts 'redirect_pages: ' + site_hash[domain]['redirect_pages'].to_s
      end

      if ( [301, 302].any? {|status| crawled_page.code == status}  )
        site_hash[domain]['redirect_pages'] += 1
        if site_hash[domain]['redirect_pages'] < 25 # if its done this >50 times, strong chance its caught in some redirect loop
          crawl_url(crawled_page.redirect_to.to_s, target_indx, site_hash, errors, storage, true)
        end
        next # since crawled_page.body will be nil if we keep going
      end


      depth = crawled_page.depth.to_s
      if depth.to_i > 1 then depth = '1' end


      crawled_page.body.scan(/[https?:\/\/]+[www.]*twitter.com\/[a-zA-Z0-9_]+/).each do |twitter|

        twitter = twitter.downcase
        found = ( site_hash[domain]['twitters0'] + site_hash[domain]['twitters1'] ).any? {|tw| tw.include? twitter.split('/').last }


        bad_words = ['share', 'widgets', 'intent', 'search']
        true_statements = [
          !twitter.empty?,
          !(bad_words.any?{|word| twitter.include?(word)}),
          !found,
        ]


        site_hash[domain]['twitters'+depth] += [twitter] unless true_statements.include? false

      end



      crawled_page.body.scan(/[\w\d]+[\w\d.-]@[\w\d.-]+\.\w{2,6}/).each do |address|

        address = address.downcase

        if address.empty?
          found = true
        else
          found = ( site_hash[domain]['emails0'] + site_hash[domain]['emails1'] ).any? {|em| em.include? address }
        end

        if TLDS.any? {|tld| address.split('.').last == tld }
          good_pages_for_emails = ['contact', 'support']
          #if crawled_page.url.to_s.include?('contact') then else end
          good_pages_for_emails.any?{|p| crawled_page.url.to_s.include? p } ? mod_depth = '0' : mod_depth = depth
          site_hash[domain]['emails'+mod_depth]  += [address] if !found
        end
        # if Address.first(:email => address).nil?

        #   puts 'found email ---------------------------'
        #   puts address


        #   page = Page.first_or_create(
        #     { :url => crawled_page.url.to_s },
        #     {
        #       :site => site,
        #       :created_at => Time.now
        #     }
        #   )

        #   Address.create(
        #     :email => address,
        #     :site => site,
        #     :page => page,
        #     :created_at => Time.now
        #   )

        #   puts address
        # end

      end


      if crawled_page.depth == 0 && !is_redirect # we're on the first non-redirect page
        #### remember that on the previous ones, we wanted to scan source code
        #### for this one, we only want to scan VISIBLE TEXT (or else it gets all sorts of random numbers)
        crawled_page.doc.inner_text.scan(/[+\d()]+.[+\d()]+.\d+.\d+.\d+/).each do |num|
          begin
          parsed_val = GlobalPhone.parse(num) if (num[0] == '+') || (num.gsub(/\D/, '').size == 9) || (num.gsub(/\D/, '').size == 10)
          if parsed_val
            site_hash[domain]['country'] += [parsed_val.territory.name] unless site_hash[domain]['country'].include? parsed_val.territory.name
          end
          rescue 
            binding.pry
          end
        end
      end



      site_hash[domain]['pages_crawled'] += 1



    end


  end
  rescue Exception => e


    puts "error ---------------------------"
    puts e



  end
  puts ''
  puts ''
  puts ''

end






domains = ['http://www.azuqua.com']   ### make sure all urls have http in beginning, else relative url errors will occur
# domains = domains.shuffle[0..10]
# domains = ['http://bexargoods.com']


# object1 = Marshal.load(File.read('../mashape/"hs-analytics"/response_object_1')); 0
# arr = object1.body['hits']['hits']; 0
# domains = []
# arr.each_with_index do |i,indx|
#   # puts 'jrb + ' + indx.to_s
#   # all sites seem to have redirect urls (and we only care about the ultimate domain so follow those)
#   domains << 'http://'+get_domain(i['fields']['redirect'][0])
# end ; 0
# domains = domains.shuffle[0..20]

domains = SITES_TO_CRAWL
REDIS = Redis.new(:port => 6379)


puts 'Started at: ' + Time.now.to_s
site_hash = {}
errors = {}
domains.shuffle.each_with_index do |target, target_indx|

  if target_indx > 1000 then next end

  storage = Anemone::Storage.Redis
  crawl_url(target, target_indx, site_hash, errors, storage, false)
  REDIS.set('timestamp_'+target, Time.now)

end




File.open("site_hash1000", 'wb') {|f| f.write(Marshal.dump(site_hash)) }
File.open("errors1000", 'wb') {|f| f.write(Marshal.dump(errors)) }
puts 'Completed at: ' + Time.now.to_s


binding.pry

