VAGRANTFILE_API_VERSION = '2'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'ubuntu/trusty64'

  config.vm.provision :shell, inline: <<-eos
    apt-get install -y software-properties-common
    apt-add-repository ppa:brightbox/ruby-ng
    apt-get update
    apt-get install -y ruby2.2 ruby-switch
    ruby-switch --set ruby2.2
    gem install bundler
    apt-get install -y default-jre
    apt-get install -y curl unzip
  eos

  config.vm.provision :shell, privileged: false, inline: <<-eos
    curl -O http://nand2tetris.org/software/nand2tetris.zip
    unzip nand2tetris.zip
    echo 'export EMULATOR=~/nand2tetris/tools/CPUEmulator.sh' >> ~/.profile
  eos
end
