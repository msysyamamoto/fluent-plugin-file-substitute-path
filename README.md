# fluent-plugin-file-substitute-path

This plugin generates from the value of the specified field the path of the file to be output.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fluent-plugin-file-substitute-path'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-file-substitute-path

## Configuration

### path_prefix (required)

Path prefix of output files.

### path_key (required)

Set the key of the field where part of the path is stored.

### append

If set to `true`, append the data to the file. The default is `false`.

### compress

If set to `gzip`, the output file will be compressed. The default is `nil`.

### format

see [http://docs.fluentd.org/articles/formatter-plugin-overview](http://docs.fluentd.org/articles/formatter-plugin-overview). The default is `out_file`.

### other

This plugin inherit the `Fluent::TimeSlicedOutput` class. So, you can set the configurations of the `Fluent::TimeSlicedOutput` class.
see [http://docs.fluentd.org/articles/output-plugin-overview#time-sliced-output-parameters](http://docs.fluentd.org/articles/output-plugin-overview#time-sliced-output-parameters)

## Examples

```apache
<match dummy>
    @type file_substitute_path
    path_prefix /var/log/subs
    path_key path_is_here
</match>
```

If your inputs is

```json
{"path_is_here": "/oh/my/log", "message": "hello"}
{"path_is_here": "path/to/file", "message": "world"}
```

File is created as follows

```bash
$ find /var/log/subs/**/*.log
/var/log/subs/oh/my/log.2016121314.log
/var/log/subs/path/to/file.2016121314.log

$ cat /var/log/subs/oh/my/log.2016121314.log
2016-12-13T14:15:16[TAB]dummy[TAB]{"message":"hello"}

$ cat /var/log/subs/path/to/file.2016121314.log
2016-12-13T14:15:17[TAB]dummy[TAB]{"message":"world"}
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/msysyamamoto/fluent-plugin-file-substitute-path. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

