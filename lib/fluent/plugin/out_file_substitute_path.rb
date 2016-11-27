require 'fileutils'
require 'zlib'
require 'fluent/plugin/out_file'

module Fluent
  class FileSubstitutePathOutput < FileOutput
    Plugin.register_output('file_substitute_path', self)

    config_param :extend_path_key, :string, default: "extend_path"

    def configure(conf)
      super
      @extend_path_key = conf['extend_path_key']
    end

    def format(tag, time, record)
      unless record.has_key?(@extend_path_key)
        log.warn("Undefined extend_path_key: #{@extend_path_key} ")
      end

      dup = record.dup
      extend_path = dup[@extend_path_key]
      dup.delete(@extend_path_key)

      data = @formatter.format(tag, time, dup)
      [extend_path, data].to_msgpack
    end

    def write(chunk)
      paths = {}
      chunk.msgpack_each do |(extend_path, data)|
        path = build_path(chunk.key, extend_path)
        if paths.has_key?(path)
          paths[path] += data
        else
          paths[path] = data
        end
      end

      paths.each do |path, data|
        FileUtils.mkdir_p(File.dirname(path), mode: DEFAULT_DIR_PERMISSION)

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

    def build_path(time_string, extend_path)
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
