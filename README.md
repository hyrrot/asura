Asura
=====

Asura is an automated shell scripting tool especially for remote server operation.
Asura's goal is to provide "an executable operation manual for remote servers."

* Automates log-in to servers via ssh (Telnet support is planned)
* Automates user switching with "sudo su"

This is an alpha version. You should not use it for production servers.

Usage
=====

    require 'asura/asura'
    password = "open_sesame"
    ["azelea", "orchid"].each do |host|
      Asura::AsuraCommand.ssh(host, password) do |ssh|
        ssh.sudo_su("nathan", password) do
          ssh.bash do
            ssh.crontab "-l"
          end
        end
      end
    end

