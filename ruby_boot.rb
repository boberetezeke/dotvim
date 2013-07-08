module VIM
  def assign_key
  end

  def self.update
    Dir[".vim/ruby/*.rb"].each do |rb_file|
      Vim::command("rubyfile #{rb_file}")
    end
  end
end

VIM::update

