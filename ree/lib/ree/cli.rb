# frozen_string_literal: true

module Ree
  module CLI
    autoload :Init, 'ree/cli/init'
    autoload :GeneratePackagesSchema, 'ree/cli/generate_packages_schema'
    autoload :GeneratePackage, 'ree/cli/generate_package'
    autoload :GenerateTemplate, 'ree/cli/generate_template'
    autoload :Indexing, 'ree/cli/indexing'
    autoload :SpecRunner, 'ree/cli/spec_runner'
  end
end
