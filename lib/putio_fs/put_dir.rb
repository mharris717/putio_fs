class File
  class << self
    def create(filename,str)
      open(filename,"w") do |f|
        f << str
      end
    end
    def append(filename,str)
      open(filename,"a") do |f|
        f << str
      end
    end
    def pp(filename,obj)
      require 'pp'
      open(filename,"w") do |f|
        PP.pp obj,f
      end
    end
  end
end


module PutioFs
  class PutFile
    include FromHash
    attr_accessor :id, :name, :parent_id, :content_type, :put_dir
    def initialize(ops)
      [:id, :name, :parent_id, :content_type, :put_dir].each do |m|
        send("#{m}=",ops[m.to_s])
      end
    end
    def directory?
      content_type =~ /directory/
    end
    def file?
      !directory?
    end
    fattr(:full_path) do
      if id == 0
        "/"
      elsif parent_id == 0
        "/#{name}"
      else
        "#{parent_file.full_path}/#{name}"
      end
    end
    fattr(:parent_file) do
      raise "shouldn't be here" if id == 0
      raise inspect unless put_dir
      put_dir.hash_by_id[parent_id]
    end
    fattr(:mp4_url) do
      puts "in mp4 url"
      #put_dir.api.mp4_url_raw(id)
      "http://put.io/v2/files/#{id}/stream?token=75a44ac0567811e2b09f001018321b64"
    end
  end

  class PutDir
    fattr(:api) do
      token = "F0B582CP"
      #token = "75a44ac0567811e2b09f001018321b64"
      PutioApi.new(:access_token => token)
    end
    fattr(:cached_responses) do
      Hash.new do |h,k| 
        res = api.files(k) 
        File.pp PutioFs.tmp_dir+"/#{k}.dmp",res
        h[k] = res
      end
    end

    def get_files(root)
      files = cached_responses[root]
      files.map do |raw|
        file = PutFile.new(raw.merge('put_dir' => self))

        hash_by_id[file.id] ||= file
        hash_by_name[file.name] ||= file
        hash_by_path[file.full_path] ||= file

        file
      end
    end
    fattr(:hash_by_id) { {} }
    fattr(:hash_by_name) { {} }
    fattr(:hash_by_path) { {} }

    def file_for_path(path)
      hash_by_path["/"] ||= PutFile.new('id' => 0, 'put_dir' => self)
      hash_by_path[path]
    end
    def contents(path)
      puts "contents for #{path}"
      files = get_files(file_for_path(path).id)
      files.map { |x| x.name }
    end
    def file?(path)
      puts "file? for #{path}"
      file = hash_by_path[path]
      file.file?
    end
    def directory?(path)
      puts "directory? for #{path}"
      file = hash_by_path[path]
      file.directory?
    end
    def read_file(path)
      puts "read_file for #{path}"
      file = file_for_path(path)
      file.mp4_url
    end
    def size(path)
      puts "size for #{path}"
      read_file(path).size
    end
  end
end