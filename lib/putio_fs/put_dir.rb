module PutioFs
  class PutDir
    fattr(:api) do
      token = "F0B582CP"
      PutioApi.new(:access_token => token)
    end
    fattr(:cached_responses) do
      Hash.new { |h,k| h[k] = api.files(k) }
    end
    def contents(path)
      puts "contents for #{path}"
      ["a.txt"]
    end
    def file?(path)
      puts "file? for #{path}"
      true
    end
    def read_file(virtual_path)
      puts "read_file for #{virtual_path}"
      "Hello"
    end
    def size(path)
      puts "size for #{path}"
      read_file(path).size
    end
  end
end