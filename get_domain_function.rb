def get_domain(url)
    redirect_url = url.downcase
    if redirect_url.include? '-'
      redirect_url = redirect_url.gsub('-','_____') # HACK couldn't figure out how to get regex to accept '-' 1hr dont bother
    end
    new_url = redirect_url.scan(/(?:https?:\/\/)([a-zA-Z0-9_]+(?:\.\w+)+)/)[0][0]
    new_url_split = new_url.split('.')
    first_indx = 1
    found_match = false
    finds = []
    special = false
    TLDS.each do |tld|



      # ["news", "islandcreekoysters", "com"]  # size 3
      # ["econveyance","com"] # size 2
      # ["efloristmarketplace","co","uk"] # size 3
      # so it cant be equal to 0 or 1 if size >=3
      # if size 3, it can be equal to 2 or 1


      # weird edge case not handled: you.can.go.far.com  most times nobody does more than go.far.com

      found_indx = new_url_split.index{|x| x == tld} # finds occurrence of a matching tld
      finds << found_indx
      
      # for size 3 or greater
      if found_indx && found_indx>=1 && new_url_split.size >= 3
        if(!found_match)
          first_indx = found_indx
          found_match = true
        else
          # first>found for cases where something .co.uk  the first_indx should then be set to uk
          # found minus first condition for www.google.com (google is a TLD)
          if first_indx>found_indx && (first_indx - found_indx == 1)
            first_indx = found_indx
          end
        end
      end
      # for size 2
      if found_indx && new_url_split.size == 2 
        first_indx = 1
      end

      # special case when the first break is a tld
      if ( finds.include? 0 ) && ( finds.include? 1 )
        special = true
      end

    end
    if special 
      first_indx += 1 
    end

    # get one before it, and get everything after it
    final_url = new_url_split[(first_indx-1)..-1].join('.')
    final_url = final_url.gsub('_____','-')
    ####puts redirect_url.gsub('_____','-') + ';' + final_url
    #puts '------'
    return final_url
end



# ############# TEST CASES
# get_domain('http://news.islandcreekoysters.com')
# get_domain('http://www.news.islandcreekoysters.com')
# get_domain('https://www.eonveyance.com')
# get_domain('http://eonveyance.com')
# get_domain('http://www.efloristmarketplace.co.uk')
# get_domain('https://efloristmarketplace.co.uk')
# get_domain('https://my.google.com') ## my is a TLD
# get_domain('https://org.google.co.uk')
# get_domain('https://org.com.co.uk')
# get_domain('http://teaprincess.com.au')
# get_domain('http://marcscarlett.com.au')
