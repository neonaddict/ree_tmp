# frozen_string_literal: true

RSpec.describe Ree::ImportDsl do
  context "first constant is not declared in the parent scope" do
    it {
      module TestModule1
        class TestClass
          ExistingClass = Class.new
          EXISTING_CONST = 'const'

          class << self
            def result
              Ree::ImportDsl.new.execute(
                self,
                Proc.new {
                  MissingClass.as(Missing) & ExistingClass & FOO.as(FOO_CONST) & EXISTING_CONST
                }
              )
            end
          end
        end
      end

      list, removed_consts = TestModule1::TestClass.result

      expect(list.map(&:name)).to eq(['MissingClass', 'ExistingClass', 'FOO', 'EXISTING_CONST'])
    }
  end

  context "constant from top parent scope" do
    it {
      module TestModule5
        HTTP = 'HTTP'

        class TestClass
          EXISTING_CONST = 'const'

          class << self
            def result
              Ree::ImportDsl.new.execute(
                self,
                Proc.new {
                  MissingClass.as(Missing) & HTTP & FOO.as(FOO_CONST) & EXISTING_CONST
                }
              )
            end
          end
        end
      end

      list, removed_consts = TestModule5::TestClass.result

      expect(list.map(&:name)).to eq(['MissingClass', 'HTTP', 'FOO', 'EXISTING_CONST'])
    }
  end

  context "first constant is declared in the parent scope" do
    it {
      module TestModule2
        class TestClass
          ExistingClass = Class.new
          EXISTING_CONST = 'const'

          class << self
            def result
              Ree::ImportDsl.new.execute(
                self,
                Proc.new {
                  ExistingClass & MissingClass.as(Missing) & EXISTING_CONST & FOO.as(FOO_CONST)
                }
              )
            end
          end
        end
      end

      list, removed_consts = TestModule2::TestClass.result

      expect(list.map(&:name)).to eq(['ExistingClass', 'MissingClass', 'EXISTING_CONST', 'FOO'])
    }
  end

  context "first constant is a missing constant" do
    it {
      module TestModule3
        class TestClass
          ExistingClass = Class.new
          EXISTING_CONST = 'const'

          class << self
            def result
              Ree::ImportDsl.new.execute(
                self,
                Proc.new {
                  FOO.as(FOO_CONST) & MissingClass.as(Missing)
                }
              )
            end
          end
        end
      end

      list, removed_consts = TestModule3::TestClass.result

      expect(list.map(&:name)).to eq(['FOO', 'MissingClass'])
    }
  end

  context "first constant is an existing constant" do
    it {
      module TestModule4
        class TestClass
          ExistingClass = Class.new
          EXISTING_CONST = 'const'

          class << self
            def result
              Ree::ImportDsl.new.execute(
                self,
                Proc.new {
                  EXISTING_CONST & FOO.as(FOO_CONST) & MissingClass.as(Missing)
                }
              )
            end
          end
        end
      end

      list, removed_consts = TestModule4::TestClass.result

      expect(list.map(&:name)).to eq(['EXISTING_CONST', 'FOO', 'MissingClass'])
    }
  end

  it {
    module TestModule5
      class TestClass
        ExistingClass = Class.new
        EXISTING_CONST = 'const'

        class << self
          def result
            Ree::ImportDsl.new.execute(
              self,
              Proc.new {
                EXISTING_CONST & FOO.as(FOO_CONST) & MissingClass.as(Missing) & ExistingClass.as(NewClass)
              }
            )
          end
        end
      end
    end

    list, removed_consts = TestModule5::TestClass.result

    expect(list.map { _1.get_as&.name || _1.name } ).to eq(['EXISTING_CONST', 'FOO_CONST', 'Missing', 'NewClass'])

    expect(removed_consts.size).to eq(2)
    expect(removed_consts.first.name).to eq(:EXISTING_CONST)
    expect(removed_consts.last.name).to eq(:ExistingClass)
  }

  context "modules with const_missing" do
    it {
      # setup module with const missing
      module ConstMissMod
        def self.append_features(base)
          base.class_eval do
            return if defined?(@_const_missing) && @_const_missing
            @_const_missing = instance_method(:const_missing)
            remove_method(:const_missing)
          end
          super
        end

        def self.exclude_from(base)
          base.class_eval do
            define_method :const_missing, @_const_missing
            @_const_missing = nil
          end
        end

        def const_missing(const_name)
          raise "inConstMissMod"
        end
      end

      Module.class_eval { include ConstMissMod }

      expect{ SomeConstant }.to raise_error("inConstMissMod")

      module TestModule1
        class TestClass
          ExistingClass = Class.new
          EXISTING_CONST = 'const'

          class << self
            def result
              Ree::ImportDsl.new.execute(
                self,
                Proc.new {
                  MissingClass.as(Missing) & ExistingClass & FOO.as(FOO_CONST) & EXISTING_CONST
                }
              )
            end
          end
        end
      end

      list, removed_consts = TestModule1::TestClass.result

      # check that original const missing was set up again
      
      expect{ SomeConstant }.to raise_error("inConstMissMod")

      ConstMissMod.exclude_from(Module)
    }
  end
end
