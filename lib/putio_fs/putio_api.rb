module PutioFs
  class PutioApi
    include FromHash
    attr_accessor :access_token
    
    def url(sub,data={})
      require 'open-uri'
      url = "https://api.put.io/v2/#{sub}?oauth_token=#{access_token}"
      data.each do |k,v|
        url += "&#{k}=#{v}"
      end
      puts "getting #{url}"
      url
    end
    
    def get(sub,data={})
      json = open(url(sub,data)).read
      JSON.parse(json)
    end
    
    def post(sub,data={})
      require 'net/http'
      
      uri = URI(url(sub))
      req = Net::HTTP::Post.new(uri.path)
      data['oauth_token'] = access_token
      req.set_form_data(data)
      
      body = nil
      res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) do |http|
        body = http.request(req).body
      end
      puts "BODY #{body.inspect}"
      body = JSON.parse(body)
      puts "BODY2 #{body.class} #{body.inspect}"
      body
    end
    
    def files(root=0)
      res = get "files/list", :parent_id => root
      res['files']
    end
    
    def upload(file)
      post "transfers/add", :url => file, :callback_url => "http://putbay.io/media_jobs/putio_callback"
    end
    
    def movie_file_id(root)
      info = file_info(root)
      return root if info['content_type'] =~ /video/
      
      res = files(root)
      raise "no files found for #{root}" unless res
      #pp res
      
      cd1 = res.find { |x| x['content_type'] =~ /directory/ && x['name'].to_s.strip.downcase == 'cd1' }
      if cd1
        movie_file_id(cd1['id'])
      else
        res = res.reject { |x| x['content_type'] =~ /directory/ }.sort_by { |x| x['size'].to_i }[-1]
        raise "no movie file for #{root}" unless res
        res["id"]
      end
    end
    
    def file_info(id)
      res = get "files/#{id}"
      res['file']
    end
    
    def transfer_file_id(id)
      res = get "transfers/#{id}"
      puts res.inspect
      return nil unless res && res['transfer']
      res['transfer']['file_id']
    end
    
    def mp4_url_raw(id)
      info = file_info(id)
      if info['content_type'] =~ /mp4/
        url("files/#{id}/download")
      else
        url("files/#{id}/mp4/download")
      end
    end
    
    def mp4_url_for_folder(root)
      movie = movie_file_id(root)
      mp4_url_raw(movie)
    end
    
    def search(keyword,ops={})
      query = "\"#{keyword}\""
      query = CGI.escape(query)
      ops.each { |k,v| query += "%20#{k}:#{v}" }
      sub = "files/search/#{query}"
      res = get sub
      res['files']
    end
    
    class << self
      def test
        user = User.first
        api = new(:access_token => user.access_token)
        require 'pp'
        pp api.files
      end
    end
  end
end