module Fluent
  class FileSubstitutePath < FileOutput
    Plugin.register_output('file_substitute_path', self)

    config_param :extend_path_key, :string, default: "extend_path"

    def configure(conf)
      super
      @extend_path_key = conf['extend_path_key']
    end

    def format(tag, time, record)
      data = @formatter.format(tag, time, record)
      [record[@extend_path_key], data].to_msgpack
    end

    def write(chunk)
      paths = {}
      chunk.msgpack_each do |(extend_path, data)|
        path = generate_path(chunk.key, extend_path)
        if paths.has_key?(path)
          paths[path] += data
        else
          paths[path] = data
        end
      end

      paths.each do |path, data|
        case @compress
        when nil
          File.open(path, "a", DEFAULT_FILE_PERMISSION) {|f| f.write(data)}
        when :gz
          Zlib::GzipWriter.open(path) {|gz| gz.write(data)}
       end
      end
    end
    
    private

    def suffix
      case @compress
      when nil
        ''
      when :gz
        ".gz"
      end
    end

    def generate_path(time_string, extend_path)
      if @append
        "#{@path}#{extend_path}.#{time_string}#{@path_suffix}#{suffix}"
      else
        path = nil
        i = 0
        begin
          path = "#{@path}#{extend_path}.#{time_string}_#{i}#{@path_suffix}#{suffix}"
          i += 1
        end while File.exist?(path)
        path
      end
    end
  end
end
