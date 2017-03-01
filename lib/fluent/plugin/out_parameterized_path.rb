module Fluent
  class ParameterizedPathOutput < Fluent::TimeSlicedOutput
    Fluent::Plugin.register_output('parameterized_path', self)

    DEFAULT_DIR_PERMISSION = 0755
    DEFAULT_FILE_PERMISSION = 0644

    SUPPORTED_COMPRESS = {
      gz: :gz,
      gzip: :gz
    }.freeze

    config_param :path_prefix, :string, default: nil
    config_param :path_key, :string, default: nil
    config_param :format, :string, default: 'out_file'
    config_param :append, :bool, default: false
    config_param :compress, default: nil do |val|
      c = SUPPORTED_COMPRESS[val.to_sym]
      raise ConfigError, "Unsupported compression algorithm '#{compress}'" unless c
      c
    end

    def configure(conf)
      super

      raise ConfigError, "'path_prefix' parameter is required" unless @path_prefix
      raise ConfigError, "'path_key' parameter is required" unless @path_key

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
          paths[path] << data
        else
          paths[path] = data
        end
      end

      paths.each do |path, data|
        FileUtils.mkdir_p(File.dirname(path), mode: DEFAULT_DIR_PERMISSION)

        case @compress
        when nil
          File.open(path, 'ab', DEFAULT_FILE_PERMISSION) { |f| f.write(data) }
        when :gz
          File.open(path, 'ab', DEFAULT_FILE_PERMISSION) do |f|
            Zlib::GzipWriter.wrap(f) { |gz| gz.write(data) }
          end
        end
      end

      paths.keys # for test
    end

    private

    def generate_path(time_string, path)
      path_head = ''
      path_tail = ''

      if pos = path.index('*')
        path_head = path[0, pos]
        path_tail = path[pos + 1..-1]
      else
        path_head = path + '.'
        path_tail = '.log'
      end

      path = nil
      if @append
        path = "#{@path_prefix}/#{path_head}#{time_string}#{path_tail}#{@suffix}"
      else
        i = 0
        begin
          path = "#{@path_prefix}/#{path_head}#{time_string}_#{i}#{path_tail}#{@suffix}"
          i += 1
        end while File.exist?(path)
      end

      path
    end
  end
end
