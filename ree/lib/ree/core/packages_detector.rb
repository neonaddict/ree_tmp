# frozen_string_literal: true

require 'pathname'

class Ree::PackagesDetector
  # @param [String] dir Packages root dir
  # @return [ArrayOf[{name: String, entry_path: String, gem_name: Nilor[String]}]]
  def call(dir, gem_name = nil)
    if !Dir.exist?(dir)
      raise Ree::Error.new("dir does not exist: #{dir}", :invalid_dir)
    end

    names = {}
    packages = []

    package_dirs = File.join(dir, "**/package")
    Dir[package_dirs].each do |package_dir|
      next unless File.directory?(package_dir)

      dir_path = Pathname.new(package_dir)
      name = dir_path.parent.basename.to_s

      next if names.has_key?(name)

      package_rel_path = dir_path.relative_path_from(dir)

      entry_path = Ree::PathHelper.package_entry_path(package_rel_path)
      next unless File.exist?(File.join(dir, entry_path))

      names[name] = entry_path

      packages << {
        name: name.to_sym,
        entry_path: entry_path,
        gem_name: gem_name
      }
    end

    packages
  end
end