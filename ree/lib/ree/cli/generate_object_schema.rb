require 'fileutils'

module Ree
  module CLI
    class GenerateObjectSchema
      class << self
        def run(package_name:, object_path:, project_path:, silence: false)
          ENV['REE_SKIP_ENV_VARS_CHECK'] = 'true'

          path = Ree.locate_packages_schema(project_path)
          dir = Pathname.new(path).dirname.to_s

          puts "Before init"
          a1 = Time.now
          Ree.init(dir)
          puts "Ree initialized #{Time.now - a1}"

          package_name = package_name.to_sym
          object_name = object_path.split('/')[-1].split('.').first.to_sym

          # puts("Generating #{object_name}.schema.json in #{package_name} package") if !silence
          puts("Generating #{object_name}.schema.json in #{package_name} package")

          facade = Ree.container.packages_facade
          puts "Before get loaded package"
          a1 = Time.now
          package = facade.get_loaded_package(package_name)
          puts "Package #{package_name} loaded #{Time.now - a1}"

          if facade.has_object?(package_name, object_name)
            puts "Package have object #{object_name}"
            puts "Before load_package_object"
            a1 = Time.now
            object = facade.load_package_object(package_name, object_name)
            puts "After load_package_object #{Time.now - a1}"
            puts "Before write_object_schema"
            a1 = Time.now
            Ree.write_object_schema(package.name, object.name)
            puts "After write_object_schema #{Time.now - a1}"
            puts "Before dump package schema"
            a1 = Time.now
            facade.dump_package_schema(package_name)
            puts "After dump package schema #{Time.now - a1}"
          else
            puts "Package don't have object #{object_name}"
            file_path = File.join(dir, object_path)
            puts "file_path #{file_path}"

            if File.exist?(file_path)
              puts "File exists #{file_path}"
              puts "Before load file"
              a1 = Time.now
              facade.load_file(file_path, package_name)
              puts "After load file #{Time.now - a1}"

              puts "Before dump package schema"
              a1 = Time.now
              facade.dump_package_schema(package_name)
              puts "After dump package schema #{Time.now - a1}"

              if facade.has_object?(package_name, object_name)
                puts "Package now have object #{object_name}"
                puts "Before write_object_schema"
                a1 = Time.now
                Ree.write_object_schema(package_name, object_name)
                puts "After write_object_schema #{Time.now - a1}"
              end
            else
              raise Ree::Error.new("package file not found: #{file_path}")
            end
          end

          # puts("done") if !silence
          puts("done")
        end
      end
    end
  end
end
