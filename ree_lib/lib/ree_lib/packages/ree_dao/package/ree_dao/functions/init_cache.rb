# frozen_string_literal: true

class ReeDao::InitCache
  include Ree::FnDSL

  fn :init_cache do
    link :dao_cache
  end

  contract(None => nil)
  def call
    dao_cache.add_thread_cache(Thread.current)
    nil
  end
end