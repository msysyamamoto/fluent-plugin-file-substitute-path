module Fluent
  # fluent-plugin-file-substitute-path
  class FileSubstitutePathOutput < Fluent::TimeSlicedOutput
    Plugin.register_output('file_substitute_path', self)

    SUPPORTED_COMPRESS = {
      gz: :gz,
      gzip: :gz
    }.freeze

    config_set_default :time_slice_format, '%Y%m%d'

    config_param :compress, default: nil do |val|
      c = SUPPORTED_COMPRESS[val.to_sym]
      raise ConfigError, "Unsupported compression algorithm '#{compress}'" unless c
      c
    end

    config_param :format, :string, default: 'out_file'
    config_param :path_key, :string, default: 'path'
    config_param :append, :bool, default: false
    config_param :root_dir, :string, default: '/tmp'

    def configure(conf)
      super
      @formatter = Plugin.new_formatter(@format)
      @formatter.configure(conf)

      @suffix = case @compress
                when nil
                  ''
                when :gz
                  '.gz'
                end
    end

    def format(tag, time, record)
      log.warn("Undefined key: #{@path_key}") unless record.key?(@path_key)

      path = record[@path_key]
      dup = record.dup
      dup.delete(@path_key)

      data = @formatter.format(tag, time, dup)
      [path, data].to_msgpack
    end

    def write(chunk)
      paths = {}
      chunk.msgpack_each do |(path, data)|
        path = generate_path(chunk.key, path)
        if paths.key?(path)
          paths[path] += data
        else
          paths[path] = data
        end
      end

      paths.each do |path, data|
        FileUtils.mkdir_p(File.dirname(path), mode: DEFAULT_DIR_PERMISSION)

        case @compress
        when nil
          File.open(path, 'a', DEFAULT_FILE_PERMISSION) { |f| f.write(data) }
        when :gz
          File.open(path, 'a', DEFAULT_FILE_PERMISSION) do |f|
            Zlib::GzipWriter.wrap(f) { |gz| gz.write(data) }
          end
        end
      end

      paths.keys # for test
    end

    private

    def generate_path(time_string, path)
      path_prefix = ''
      path_suffix = ''

      if pos = path.index('*')
        path_prefix = path[0, pos]
        path_suffix = path[pos + 1..-1]
      else
        path_prefix = path + '.'
        path_suffix = '.log'
      end

      path = nil
      if @append
        path = "#{@root_dir}/#{path_prefix}#{time_string}#{path_suffix}#{@suffix}"
      else
        i = 0
        begin
          path = "#{@root_dir}/#{path_prefix}#{time_string}_#{i}#{path_suffix}#{@suffix}"
          i += 1
        end while File.exist?(path)
      end

      path
    end
  end
end
