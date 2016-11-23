module Fluent
  class FileSubstitutePath < FileOutput
    Plugin.register_output('file_substitute_path', self)
  end
end
