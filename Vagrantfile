
require 'yaml'

dir = File.dirname(File.expand_path(__FILE__))
settings = YAML.load_file("#{dir}/config.yaml")

#If your Vagrant version is lower than 1.5, you can still use this provisioning
#by commenting or removing the line below and providing the config.vm.box_url parameter,
#if it's not already defined in this Vagrantfile. Keep in mind that you won't be able
#to use the Vagrant Cloud and other newer Vagrant features.
Vagrant.require_version ">= 1.5"

# Check to determine whether we're on a windows or linux/os-x host,
# later on we use this to launch ansible in the supported way
# source: https://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each { |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable? exe
    }
  end
  return nil
end

################################################################################
#                   VAGRANT REQUIRED PLUGINS
################################################################################
settings['vagrant']['required_plugins'].each do |plugin|
  system "vagrant plugin install #{plugin}" unless Vagrant.has_plugin? plugin
end


################################################################################
#                   VAGRANT CONFIGURATION
################################################################################
Vagrant.configure("2") do |config|


  ################################################################################
  #                   VAGRANT PLUGINS CONFIGURATION
  ################################################################################
  # Vagrant vbguest
  # @see: https://github.com/dotless-de/vagrant-vbguest
  if Vagrant.has_plugin?('vagrant-vbguest')
    # set auto_update to false, if you do NOT want to check the correct
    # additions version when booting this machine
    config.vbguest.auto_update = false

    # do NOT download the iso file from a webserver
    config.vbguest.no_remote = true
  end


  ##############################################################################
  #                  VIRTUAL MACHINE SETTINGS
  #
  # @see: https://docs.vagrantup.com/v2/vagrantfile/machine_settings.html
  #
  ##############################################################################
  config.vm.provider :virtualbox do |vb|
    vb.customize [
      "modifyvm", :id,
      "--name", settings['vm']['hostname'],
      "--cpus", settings['vm']['cpus'].to_i,
      "--memory", settings['vm']['memory'].to_i,
      "--natdnshostresolver1", "on",
    ]
  end

  # Hostname Definition
  if settings['vm']['hostname'].to_s.strip.length != 0
    config.vm.hostname = settings['vm']['hostname']
  end

  # Box base settings
  config.vm.box     = settings['vm']['box']
  config.vm.box_url     = settings['vm']['box_url']

  # PostUp Message
  if !settings['vm']['post_up_message'].nil?
    config.vm.post_up_message = "#{settings['vm']['post_up_message']}"
  end


  ##############################################################################
  #                       NETWORK
  #
  # @see: https://docs.vagrantup.com/v2/networking/
  #
  ##############################################################################
  if settings['vm']['network']['private_network'].to_s != ''
    config.vm.network 'private_network', ip: settings['vm']['network']['private_network']
  end
  if settings['vm']['network']['bridge_network']['install'].nil?
    config.vm.network 'public_network', bridge: "#{settings['vm']['network']['bridge_network']['interface_name']}"
  end

  settings['vm']['network']['forwarded_port'].each do |i, port|
    if port['guest'] != '' && port['host'] != ''
      config.vm.network :forwarded_port, guest: port['guest'].to_i, host: port['host'].to_i
    end
  end

  config.vm.usable_port_range = (settings['vm']['usable_port_range']['start'].to_i..settings['vm']['usable_port_range']['stop'].to_i)

  ##############################################################################
  #                       SYNCED FOLDERS
  #
  # @see: https://docs.vagrantup.com/v2/synced-folders/
  #
  ##############################################################################
  settings['vm']['synced_folder'].each do |i, folder|
    if folder['source'] != '' && folder['target'] != ''
      sync_owner = !folder['sync_owner'].nil? ? folder['sync_owner'] : 'www-data'
      sync_group = !folder['sync_group'].nil? ? folder['sync_group'] : 'www-data'

      if folder['sync_type'] == 'nfs'
        if Vagrant.has_plugin?('vagrant-bindfs')
          config.vm.synced_folder "#{folder['source']}", "/mnt/vagrant-#{i}", id: "#{i}", type: 'nfs'
          config.bindfs.bind_folder "/mnt/vagrant-#{i}", "#{folder['target']}", user: sync_owner, group: sync_group
        else
          config.vm.synced_folder "#{folder['source']}", "#{folder['target']}", id: "#{i}", type: 'nfs'
        end
      elsif folder['sync_type'] == 'smb'
        config.vm.synced_folder "#{folder['source']}", "#{folder['target']}", id: "#{i}", type: 'smb'
      elsif folder['sync_type'] == 'rsync'
        rsync_args = !folder['rsync']['args'].nil? ? folder['rsync']['args'] : ['--verbose', '--archive', '-z']
        rsync_auto = !folder['rsync']['auto'].nil? ? folder['rsync']['auto'] : true
        rsync_exclude = !folder['rsync']['exclude'].nil? ? folder['rsync']['exclude'] : ['.vagrant/']

        config.vm.synced_folder "#{folder['source']}", "#{folder['target']}", id: "#{i}",
          rsync__args: rsync_args, rsync__exclude: rsync_exclude, rsync__auto: rsync_auto, type: 'rsync', group: sync_group, owner: sync_owner
      elsif settings['vm']['chosen_provider'] == 'parallels'
        config.vm.synced_folder "#{folder['source']}", "#{folder['target']}", id: "#{i}",
          group: sync_group, owner: sync_owner, mount_options: ['share']
      else
        config.vm.synced_folder "#{folder['source']}", "#{folder['target']}", id: "#{i}",
          group: sync_group, owner: sync_owner, mount_options: ['dmode=775', 'fmode=764']
      end
    end
  end

  ##############################################################################
  #                       SSH SETTINGS
  #
  # @see: https://docs.vagrantup.com/v2/vagrantfile/ssh_settings.html
  #
  ##############################################################################
  if !settings['ssh']['username'].nil?
    config.ssh.username = "#{settings['ssh']['username']}"
  end
  if !settings['ssh']['password'].nil?
    config.ssh.password = "#{settings['ssh']['password']}"
  end
  if !settings['ssh']['host'].nil?
    config.ssh.host = "#{settings['ssh']['host']}"
  end
  if !settings['ssh']['port'].nil?
    config.ssh.port = "#{settings['ssh']['port']}"
  end
  if !settings['ssh']['guest_port'].nil?
    config.ssh.guest_port = settings['ssh']['guest_port']
  end
  if !settings['ssh']['shell'].nil?
    config.ssh.shell = "#{settings['ssh']['shell']}"
  end
  if !settings['ssh']['forward_agent'].nil?
    config.ssh.forward_agent = settings['ssh']['forward_agent']
  end
  if !settings['ssh']['forward_x11'].nil?
    config.ssh.forward_x11 = settings['ssh']['forward_x11']
  end
  if !settings['ssh']['keep_alive'].nil?
    config.ssh.keep_alive = settings['ssh']['keep_alive']
  end

  #############################################################
  # Ansible provisioning (you need to have ansible installed)
  #############################################################
  if which('ansible-playbook')
    config.vm.provision "ansible" do |ansible|
      ansible.playbook = settings['provision']['ansible']['playbook']
      # Temportally disabled. Uncomment for specify the inventory files path
      if settings['provision']['ansible']['inventory_path'].to_s != ''
        ansible.inventory_path = settings['provision']['ansible']['inventory_path']
      end

      # Up to Vagrant 1.4, the Ansible provisioner could potentially connect
      # (multiple times) to all hosts from the inventory file.
      if settings['provision']['ansible']['limit'].to_s != ''
        ansible.limit = settings['provision']['ansible']['limit']
      end

      ansible.extra_vars = {
        private_interface: settings['vm']['network']['private_network'],
        hostname: settings['vm']['hostname'],
        settings: settings['provision']['ansible']['settings']
      }
    end
  end
end
