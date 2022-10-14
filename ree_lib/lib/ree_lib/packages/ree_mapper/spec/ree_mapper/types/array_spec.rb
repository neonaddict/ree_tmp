# frozen_string_literal: true

RSpec.describe 'ReeMapper::Array' do
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper

  let(:mapper_factory) {
    build_mapper_factory(
      strategies: [
        build_mapper_strategy(method: :cast,      output: :symbol_key_hash),
        build_mapper_strategy(method: :serialize, output: :symbol_key_hash),
        build_mapper_strategy(method: :db_dump,   output: :symbol_key_hash),
        build_mapper_strategy(method: :db_load,   output: :symbol_key_hash)
      ]
    )
  }

  let(:mapper) {
    mapper_factory.call.use(:cast).use(:serialize).use(:db_dump).use(:db_load) {
      array :tags, each: integer
      array? :ary_of_ary, each: array(each: integer)
    }
  }

  describe '#serialize' do
    it {
      expect(mapper.serialize({ tags: [1, 2], ary_of_ary: [[1]] })).to eq({ tags: [1, 2], ary_of_ary: [[1]] })
    }

    it {
      expect { mapper.serialize({ tags: 1 }) }.to raise_error(ReeMapper::TypeError, "`tags` should be an array")
    }

    it {
      expect { mapper.serialize({tags: [1], ary_of_ary: ["1"] }) }.to raise_error(ReeMapper::TypeError, "`ary_of_ary[0]` should be an array")
    }

    it {
      expect { mapper.serialize({tags: [1], ary_of_ary: [[1, "1"]] }) }.to raise_error(ReeMapper::TypeError, "`ary_of_ary[0][1]` should be an integer")
    }
  end

  describe '#cast' do
    it {
      expect(mapper.cast({ 'tags' => [1, 2] })).to eq({ tags: [1, 2] })
    }

    it {
      expect { mapper.cast({ 'tags' => 1 }) }.to raise_error(ReeMapper::TypeError, "`tags` should be an array")
    }
  end

  describe '#db_dump' do
    it {
      expect(mapper.db_dump(OpenStruct.new({ tags: [1, 2] }))).to eq({ tags: [1, 2] })
    }

    it {
      expect { mapper.db_dump(OpenStruct.new({ tags: 1 })) }.to raise_error(ReeMapper::TypeError, "`tags` should be an array")
    }
  end

  describe '#db_load' do
    it {
      expect(mapper.db_load({ 'tags' => [1, 2] })).to eq({ tags: [1, 2] })
    }

    it {
      expect { mapper.db_load({ 'tags' => 1 }) }.to raise_error(ReeMapper::TypeError, "`tags` should be an array")
    }
  end

  context 'with array of array' do
    let(:mapper) {
      mapper_factory.call.use(:serialize) {
        array :coords, each: array(each: integer)
      }
    }

    it {
      expect(mapper.serialize({ coords: [[1, 1], [2, 2]] })).to eq({ coords: [[1, 1], [2, 2]] })
    }
  end

  context 'with nullable element of array' do
    let(:mapper) {
      mapper_factory.call.use(:serialize) {
        array :tags, each: integer(null: true)
      }
    }

    it {
      expect(mapper.serialize({ tags: [1, 2, nil] })).to eq({ tags: [1, 2, nil] })
    }
  end

  context 'with optional each type' do
    it {
      expect {
        mapper_factory.call.use(:serialize) {
          array :tags, each: integer?
        }
      }.to raise_error(ArgumentError)
    }

    it {
      expect {
        mapper_factory.call.use(:serialize) {
          array :tags, each: integer(optional: true)
        }
      }.to raise_error(ArgumentError)
    }

    it {
      expect {
        mapper_factory.call.use(:serialize) {
          array :tags, each: array(each: integer, optional: true)
        }
      }.to raise_error(ArgumentError)
    }
  end

  context 'with array of hashes' do
    let(:mapper) {
      mapper_factory.call.use(:serialize) {
        array :coords do
          integer :x
          integer :y
        end
      }
    }

    it {
      expect(mapper.serialize({ coords: [{ x: 1, y: 1 }, { x: 2, y: 2 }] })).to eq({ coords: [{ x: 1, y: 1 }, { x: 2, y: 2 }] })
    }
  end

  context 'with array of hashes with key option' do
    let(:mapper) {
      mapper_factory.call.use(:serialize) {
        array :coords, key: :string do
          integer :x
          integer :y
        end
      }
    }

    it {
      expect(mapper.serialize({ coords: [{ x: 1, y: 1 }, { x: 2, y: 2 }] }))
        .to eq({ coords: [{ 'x' => 1, 'y' => 1 }, { 'x' => 2, 'y' => 2 }] })
    }
  end
end
