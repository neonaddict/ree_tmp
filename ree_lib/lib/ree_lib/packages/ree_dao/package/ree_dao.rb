# frozen_string_literal: true

require "sequel"

module ReeDao
  include Ree::PackageDSL

  package do
    depends_on :ree_array
    depends_on :ree_dto
    depends_on :ree_enum
    depends_on :ree_mapper
    depends_on :ree_string
  end

  require_relative "./ree_dao/dsl"
end
