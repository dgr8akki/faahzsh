class Faahzsh < Formula
  desc "Zsh/Bash plugin that plays a faaaah sound when a command fails"
  homepage "https://github.com/dgr8akki/faahzsh"
  url "https://github.com/dgr8akki/faahzsh/archive/refs/heads/main.tar.gz"
  version "1.0.0"
  license "MIT"

  def install
    prefix.install "faahzsh.plugin.zsh"
    prefix.install "faahzsh.plugin.bash"
    prefix.install "sounds"
  end

  def caveats
    <<~EOS
      To activate faahzsh, add the following to your shell config:

      For zsh (~/.zshrc):
        source #{opt_prefix}/faahzsh.plugin.zsh

      For bash (~/.bashrc):
        source #{opt_prefix}/faahzsh.plugin.bash

      Then reload your shell:
        source ~/.zshrc   # or source ~/.bashrc
    EOS
  end

  test do
    assert_predicate prefix/"faahzsh.plugin.zsh", :exist?
    assert_predicate prefix/"faahzsh.plugin.bash", :exist?
    assert_predicate prefix/"sounds/faaaah.wav", :exist?
  end
end
